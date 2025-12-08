# Query Fragments

Reusable GraphQL patterns for Phoenix queries.

## Project Node Wrapper

Wrap any query in project context:

```graphql
query {
  node(id: "YOUR_PROJECT_ID") {
    ... on Project {
      # Your query here
    }
  }
}
```

## Time Range

Add time filtering to any query:

```graphql
timeRange: {
  start: "2025-11-17T18:00:00Z"
  end: "2025-11-17T19:00:00Z"
}
```

Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)

## Pagination

Add to any connection query:

```graphql
query {
  spans(first: 20, after: $cursor) {
    edges {
      cursor
      node {
        # fields
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

## Sorting

Sort any span query:

```graphql
sort: {col: COLUMN, dir: DIRECTION}
```

Columns: `startTime`, `endTime`, `latencyMs`, `tokenCountTotal`,
`tokenCountPrompt`, `tokenCountCompletion` Directions: `asc`, `desc`

## Basic Span Fields

Minimal span data:

```graphql
{
  id
  name
  spanKind
  statusCode
  latencyMs
  startTime
}
```

## Token Fields

Add to LLM spans:

```graphql
{
  tokenCountTotal
  tokenCountPrompt
  tokenCountCompletion
}
```

## Cost Fields

Add to any span:

```graphql
{
  costSummary {
    total {
      cost
      tokens
    }
    prompt {
      cost
      tokens
    }
    completion {
      cost
      tokens
    }
  }
}
```

## Trace Context

Add to any span:

```graphql
{
  trace {
    traceId
    numSpans
    latencyMs
  }
}
```

## Hierarchy Fields

Parent/child relationship:

```graphql
{
  parentId
  numChildSpans
  propagatedStatusCode
}
```

## I/O Fields

Get input/output (large data):

```graphql
{
  input {
    value
  }
  output {
    value
  }
  attributes
}
```

## Combining Fragments

### Recent LLM Calls with Cost

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 10
        filterCondition: "span_kind == 'LLM'"
        timeRange: {
          start: "2025-11-17T00:00:00Z"
          end: "2025-11-18T00:00:00Z"
        }
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            latencyMs
            tokenCountTotal
            costSummary {
              total {
                cost
                tokens
              }
            }
            startTime
          }
        }
      }
    }
  }
}
```

### Failed Operations with Context

```graphql
query {
  node(id: "PROJECT_ID") {
    ... on Project {
      spans(
        first: 20
        filterCondition: "status_code == 'ERROR'"
        sort: { col: startTime, dir: desc }
      ) {
        edges {
          node {
            id
            name
            spanKind
            statusCode
            statusMessage
            latencyMs
            startTime
            trace {
              traceId
            }
          }
        }
      }
    }
  }
}
```

## Common Variables

Use GraphQL variables for reusability:

```graphql
query GetSpans($projectId: GlobalID!, $filter: String!, $limit: Int!) {
  node(id: $projectId) {
    ... on Project {
      spans(first: $limit, filterCondition: $filter) {
        edges {
          node {
            id
            name
            latencyMs
          }
        }
      }
    }
  }
}
```

**Variables:**

```json
{
  "projectId": "UHJvamVjdDoy",
  "filter": "span_kind == 'LLM'",
  "limit": 20
}
```

## See Also

- `filters.md` - Filter syntax and patterns
- `schema.md` - All available fields
- `query-patterns.md` - Advanced techniques
