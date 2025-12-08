defmodule ReactorObanSkill.Examples.ObanScheduling do
  @moduledoc """
  Self-contained examples of job scheduling patterns with Oban.

  Shows how to schedule jobs for future execution, implement
  recurring tasks, and handle delayed processing.

  ## Related Files
  - ../reference/oban-patterns.md - Oban deep dive
  - DESIGN/concepts/jobs.md - Background job architecture
  """

  # -----------------------------------------------------------------------------
  # Example 1: Delayed Execution
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Schedule job to run after delay.

  Demonstrates:
  - schedule_in option (seconds)
  - Delayed job enqueueing
  - Use cases for delays
  """
  def example_delayed_execution do
    quote do
      defmodule MyApp.Jobs.Workers.DelayedWorker do
        use Oban.Worker, queue: :default

        @impl Oban.Worker
        def perform(%Oban.Job{args: args}) do
          %{"notification_id" => id} = args
          send_notification(id)
          :ok
        end

        defp send_notification(id) do
          # Send notification
          :ok
        end
      end

      # ✅ Schedule to run in 5 minutes (300 seconds)
      %{"notification_id" => "notif-123"}
      |> MyApp.Jobs.Workers.DelayedWorker.new(schedule_in: 300)
      |> Oban.insert()

      # ✅ Schedule to run in 1 hour
      %{"notification_id" => "notif-456"}
      |> MyApp.Jobs.Workers.DelayedWorker.new(schedule_in: 3600)
      |> Oban.insert()

      # Use cases:
      # - Reminder notifications
      # - Retry after cooldown
      # - Rate limiting
      # - Cleanup tasks
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Scheduled At Specific Time
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Schedule job for specific datetime.

  Demonstrates:
  - scheduled_at option (DateTime)
  - Future scheduling
  - Timezone handling
  """
  def example_scheduled_at do
    quote do
      defmodule MyApp.Jobs.Workers.ReportWorker do
        use Oban.Worker, queue: :reports

        @impl Oban.Worker
        def perform(%Oban.Job{args: args}) do
          %{"report_type" => type, "user_id" => user_id} = args
          generate_report(type, user_id)
          :ok
        end

        defp generate_report(type, user_id) do
          # Generate report
          :ok
        end
      end

      # ✅ Schedule for specific time (UTC)
      scheduled_time = ~U[2025-01-01 00:00:00Z]

      %{"report_type" => "monthly", "user_id" => user.id}
      |> MyApp.Jobs.Workers.ReportWorker.new(scheduled_at: scheduled_time)
      |> Oban.insert()

      # ✅ Schedule for tomorrow at 9 AM
      tomorrow_9am =
        DateTime.utc_now()
        |> DateTime.add(1, :day)
        |> DateTime.to_date()
        |> DateTime.new!(~T[09:00:00], "Etc/UTC")

      %{"report_type" => "daily", "user_id" => user.id}
      |> MyApp.Jobs.Workers.ReportWorker.new(scheduled_at: tomorrow_9am)
      |> Oban.insert()

      # Use cases:
      # - End-of-day reports
      # - Scheduled maintenance
      # - Campaign launches
      # - Batch processing windows
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Recurring Jobs with Cron
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Recurring jobs using Oban cron plugin.

  Demonstrates:
  - Cron plugin configuration
  - Recurring job schedules
  - Cron expression syntax
  """
  def example_recurring_jobs do
    quote do
      # config/config.exs
      config :my_app, Oban,
        repo: MyApp.Repo,
        queues: [
          default: 10,
          maintenance: 2
        ],
        plugins: [
          # ✅ Cron plugin for recurring jobs
          {Oban.Plugins.Cron,
           crontab: [
             # Every day at 2 AM - cleanup old records
             {"0 2 * * *", MyApp.Jobs.Workers.DailyCleanup},
             # Every hour - sync external data
             {"0 * * * *", MyApp.Jobs.Workers.HourlySync},
             # Every Monday at 9 AM - weekly report
             {"0 9 * * 1", MyApp.Jobs.Workers.WeeklyReport},
             # Every 15 minutes - health check
             {"*/15 * * * *", MyApp.Jobs.Workers.HealthCheck},
             # First day of month at midnight - monthly billing
             {"0 0 1 * *", MyApp.Jobs.Workers.MonthlyBilling}
           ]}
        ]

      # Worker for recurring job
      defmodule MyApp.Jobs.Workers.DailyCleanup do
        use Oban.Worker,
          queue: :maintenance,
          max_attempts: 1

        require Logger

        @impl Oban.Worker
        def perform(%Oban.Job{}) do
          Logger.info("Starting daily cleanup")

          # Delete old records
          cutoff_date = DateTime.add(DateTime.utc_now(), -30, :day)

          with {:ok, deleted_count} <- cleanup_old_records(cutoff_date),
               {:ok, _} <- cleanup_old_uploads(cutoff_date),
               {:ok, _} <- vacuum_database() do
            Logger.info("Daily cleanup completed",
              records_deleted: deleted_count
            )

            :ok
          else
            {:error, reason} ->
              Logger.error("Daily cleanup failed", error: reason)
              {:error, reason}
          end
        end

        defp cleanup_old_records(cutoff_date) do
          # Delete old records
          {:ok, 150}
        end

        defp cleanup_old_uploads(cutoff_date) do
          # Delete old uploads
          {:ok, :done}
        end

        defp vacuum_database() do
          # Vacuum database
          {:ok, :done}
        end
      end

      # Cron expression format:
      # ┌───────────── minute (0 - 59)
      # │ ┌───────────── hour (0 - 23)
      # │ │ ┌───────────── day of month (1 - 31)
      # │ │ │ ┌───────────── month (1 - 12)
      # │ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
      # │ │ │ │ │
      # * * * * *

      # Common patterns:
      # "0 0 * * *"    - Daily at midnight
      # "0 */6 * * *"  - Every 6 hours
      # "*/30 * * * *" - Every 30 minutes
      # "0 9 * * 1-5"  - Weekdays at 9 AM
      # "0 0 1 * *"    - First day of month
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Retry with Exponential Backoff
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Custom backoff strategy for retries.

  Demonstrates:
  - Exponential backoff configuration
  - Custom backoff function
  - Retry timing control
  """
  def example_exponential_backoff do
    quote do
      defmodule MyApp.Jobs.Workers.ApiWorker do
        use Oban.Worker,
          queue: :external_api,
          max_attempts: 5

        require Logger

        @impl Oban.Worker
        def perform(%Oban.Job{args: args, attempt: attempt}) do
          %{"endpoint" => endpoint, "data" => data} = args

          Logger.info("Calling external API",
            endpoint: endpoint,
            attempt: attempt
          )

          case call_external_api(endpoint, data) do
            {:ok, response} ->
              Logger.info("API call succeeded")
              :ok

            {:error, :rate_limit} ->
              # ✅ Will retry with exponential backoff
              Logger.warning("Rate limited, will retry",
                attempt: attempt,
                next_retry_in: calculate_backoff(attempt)
              )

              {:error, :rate_limit}

            {:error, reason} ->
              Logger.error("API call failed", error: reason, attempt: attempt)
              {:error, reason}
          end
        end

        # Calculate exponential backoff
        # Attempt 1: 4 seconds
        # Attempt 2: 16 seconds
        # Attempt 3: 64 seconds
        # Attempt 4: 256 seconds
        defp calculate_backoff(attempt) do
          :math.pow(2, attempt + 1) |> trunc()
        end

        defp call_external_api(endpoint, data) do
          # Call external API
          {:ok, "response"}
        end
      end

      # Oban automatically applies exponential backoff between retries:
      # - First retry: ~15 seconds
      # - Second retry: ~2 minutes
      # - Third retry: ~10 minutes
      # - Fourth retry: ~1 hour
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Job Uniqueness
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Prevent duplicate jobs with uniqueness constraints.

  Demonstrates:
  - unique option configuration
  - Uniqueness period
  - Custom uniqueness keys
  - Uniqueness states
  """
  def example_job_uniqueness do
    quote do
      defmodule MyApp.Jobs.Workers.UniqueWorker do
        @moduledoc """
        Worker that prevents duplicate jobs for the same resource.
        """

        use Oban.Worker,
          queue: :default,
          max_attempts: 3,
          unique: [
            # ✅ Unique within 60 second window
            period: 60,
            # ✅ Based on resource_id argument
            keys: [:resource_id],
            # ✅ Check uniqueness in these states
            states: [:available, :scheduled, :executing]
          ]

        @impl Oban.Worker
        def perform(%Oban.Job{args: args}) do
          %{"resource_id" => id} = args
          process_resource(id)
          :ok
        end

        defp process_resource(id) do
          # Process resource
          :ok
        end
      end

      # First insert - creates job
      %{"resource_id" => "resource-123"}
      |> MyApp.Jobs.Workers.UniqueWorker.new()
      |> Oban.insert()

      # Second insert within 60 seconds - returns existing job (not duplicated)
      %{"resource_id" => "resource-123"}
      |> MyApp.Jobs.Workers.UniqueWorker.new()
      |> Oban.insert()

      # Different resource_id - creates new job
      %{"resource_id" => "resource-456"}
      |> MyApp.Jobs.Workers.UniqueWorker.new()
      |> Oban.insert()

      # Use cases:
      # - Prevent duplicate processing
      # - Debounce user actions
      # - Rate limiting per resource
      # - Idempotent job enqueueing
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Priority-Based Scheduling
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Job priority for queue ordering.

  Demonstrates:
  - priority option (0-3)
  - Queue ordering
  - Use cases for priorities
  """
  def example_job_priority do
    quote do
      defmodule MyApp.Jobs.Workers.PriorityWorker do
        use Oban.Worker, queue: :default

        @impl Oban.Worker
        def perform(%Oban.Job{args: args}) do
          %{"task_type" => type} = args
          process_task(type)
          :ok
        end

        defp process_task(type) do
          # Process task
          :ok
        end
      end

      # ✅ High priority (0 = highest)
      %{"task_type" => "critical"}
      |> MyApp.Jobs.Workers.PriorityWorker.new(priority: 0)
      |> Oban.insert()

      # ✅ Normal priority (1 = default)
      %{"task_type" => "normal"}
      |> MyApp.Jobs.Workers.PriorityWorker.new(priority: 1)
      |> Oban.insert()

      # ✅ Low priority (3 = lowest)
      %{"task_type" => "background"}
      |> MyApp.Jobs.Workers.PriorityWorker.new(priority: 3)
      |> Oban.insert()

      # Queue processes jobs in priority order:
      # 1. priority: 0 (critical)
      # 2. priority: 1 (normal)
      # 3. priority: 2 (low)
      # 4. priority: 3 (background)

      # Use cases:
      # 0 - User-facing critical tasks
      # 1 - Normal background processing
      # 2 - Low-priority batch operations
      # 3 - Cleanup and maintenance tasks
    end
  end

  # -----------------------------------------------------------------------------
  # Scheduling Patterns Summary
  # -----------------------------------------------------------------------------

  @doc """
  ## Scheduling Best Practices

  ### 1. Delayed Execution

  ✅ Use schedule_in for relative delays:
  ```elixir
  MyWorker.new(%{}, schedule_in: 300)  # 5 minutes from now
  ```

  ### 2. Specific Time Scheduling

  ✅ Use scheduled_at for absolute time:
  ```elixir
  MyWorker.new(%{}, scheduled_at: ~U[2025-01-01 00:00:00Z])
  ```

  ### 3. Recurring Jobs

  ✅ Configure cron plugin in config/config.exs:
  ```elixir
  {Oban.Plugins.Cron,
   crontab: [
     {"0 2 * * *", DailyCleanup},
     {"*/15 * * * *", HealthCheck}
   ]}
  ```

  ### 4. Job Uniqueness

  ✅ Prevent duplicates:
  ```elixir
  use Oban.Worker,
    unique: [
      period: 60,
      keys: [:resource_id],
      states: [:available, :scheduled, :executing]
    ]
  ```

  ### 5. Priority

  ✅ Set job priority (0-3):
  ```elixir
  MyWorker.new(%{}, priority: 0)  # Highest
  MyWorker.new(%{}, priority: 3)  # Lowest
  ```

  ### 6. Combining Options

  ✅ Use multiple options together:
  ```elixir
  %{"resource_id" => id}
  |> MyWorker.new(
    schedule_in: 300,
    priority: 0,
    max_attempts: 5
  )
  |> Oban.insert()
  ```

  ### 7. Timezone Considerations

  ✅ Always use UTC for scheduled_at:
  ```elixir
  # Convert from user timezone to UTC
  user_time = ~N[2025-01-01 09:00:00]
  utc_time = DateTime.from_naive!(user_time, "America/New_York")
               |> DateTime.shift_zone!("Etc/UTC")

  MyWorker.new(%{}, scheduled_at: utc_time)
  ```

  ### 8. Use Cases by Pattern

  **Immediate**: Direct Oban.insert()
  - User actions requiring background processing
  - Real-time notifications

  **Delayed**: schedule_in
  - Retry after cooldown
  - Reminder notifications
  - Rate limiting

  **Scheduled**: scheduled_at
  - Campaign launches
  - Scheduled reports
  - Maintenance windows

  **Recurring**: Cron plugin
  - Daily cleanup
  - Hourly syncs
  - Monthly billing
  - Health checks
  """
end
