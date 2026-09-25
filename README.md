# Ecommerce Analytics dbt Project

## Overview

This project is an e-commerce analytics pipeline built using **dbt Core** and **PostgreSQL**.

It demonstrates an end-to-end dbt workflow including source configuration, staging models, intermediate transformations, marts, incremental processing, data quality testing, macros, snapshots, documentation, lineage, exposures, post-hooks, and Slim CI.

---

## Project Architecture

The project follows a layered dbt architecture:

```text
Raw Sources
    ↓
Staging Layer
    ↓
Intermediate Layer
    ↓
Marts Layer
```

### Data Flow

```text
ecommerce.raw_customers
        ↓
stg_customers
        ↓
dim_customers
        ↓
fct_daily_revenue


ecommerce.raw_orders
        ↓
stg_orders
        ↓
int_orders_joined_payments
        ↓
fct_daily_revenue


ecommerce.raw_payments
        ↓
stg_payments
        ↓
int_orders_joined_payments
        ↓
fct_daily_revenue
```

The `fct_daily_revenue` model is also consumed by the
`executive_revenue_dashboard` exposure.

---

## Project Structure

```text
ecommerce_analytics/
│
├── analyses/
│   └── customer_point_in_time_lookup.sql
│
├── macros/
│   ├── cents_to_dollars.sql
│   ├── pivot_payment_methods.sql
│   └── test_non_negative.sql
│
├── models/
│   │
│   ├── staging/
│   │   ├── _staging__sources.yml
│   │   ├── _staging__models.yml
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql
│   │   └── stg_payments.sql
│   │
│   ├── intermediate/
│   │   ├── _intermediate__models.yml
│   │   └── int_orders_joined_payments.sql
│   │
│   └── marts/
│       │
│       ├── core/
│       │   ├── _core__models.yml
│       │   └── dim_customers.sql
│       │
│       └── finance/
│           ├── _finance__docs.md
│           ├── _finance__models.yml
│           ├── _finance__exposures.yml
│           ├── fct_daily_revenue.sql
│           └── payment_method_summary.sql
│
├── snapshots/
│   ├── _snapshots.yml
│   └── snap_customers.sql
│
├── tests/
│   └── assert_positive_revenue.sql
│
├── state_prod/
│   └── manifest.json
│
├── dbt_project.yml
├── TESTING_SUMMARY.md
└── README.md
```

---

## Source Tables

The project uses three raw source tables from the `raw` schema:

- `raw_customers`
- `raw_orders`
- `raw_payments`

Source freshness is configured for `raw_orders` and `raw_payments`.

The configured thresholds are:

- Warning after **12 hours**
- Error after **24 hours**

---

## Model Layers

### Staging Layer

The staging models perform light cleaning, column standardization, and type casting.

Models:

- `stg_customers`
- `stg_orders`
- `stg_payments`

All staging models are materialized as **views**.

---

### Intermediate Layer

`int_orders_joined_payments` joins staged orders and payments and calculates revenue at the order level.

It is materialized as **ephemeral**, so it does not create a physical table or view in PostgreSQL.

---

### Marts Layer

The marts layer contains business-facing analytical models.

#### `dim_customers`

Customer dimension containing one row per customer.

#### `fct_daily_revenue`

Incremental revenue model with a grain of **one row per order**.

It uses:

- `order_id` as the unique key
- `MERGE` incremental strategy
- A 3-day lookback window
- `on_schema_change='append_new_columns'`

The lookback window allows recently processed orders to be recalculated when late-arriving payments are received.

#### `payment_method_summary`

Creates one column for each configured payment method using a reusable Jinja macro and a project variable.

---

## Data Quality Testing

The project includes both built-in and custom dbt tests.

Implemented tests include:

- `unique`
- `not_null`
- `accepted_values`
- `relationships`
- Custom `non_negative` generic test
- Singular `assert_positive_revenue` test

The project also demonstrates warning severity for unexpected order status values.

Run all tests using:

```bash
dbt test
```

---

## Macros

### `cents_to_dollars`

Reusable macro used to convert revenue stored in cents into dollars.

### `pivot_payment_methods`

Uses a Jinja `for` loop and the configured `payment_methods` project variable to dynamically generate one revenue column per payment method.

### `non_negative`

Reusable custom generic test that checks numeric values are not negative.

---

## Snapshots

`snap_customers` tracks historical customer changes using dbt snapshots.

Configuration includes:

- Timestamp strategy
- `customer_id` as the unique key
- `updated_at` for change detection
- Hard-delete invalidation

The snapshot preserves historical customer versions instead of overwriting old values.

The project also includes a point-in-time analysis query:

```text
analyses/customer_point_in_time_lookup.sql
```

which uses `dbt_valid_from` and `dbt_valid_to` to identify the customer record that was active at a specific timestamp.

---

## Documentation and Lineage

Generate dbt documentation using:

```bash
dbt docs generate
```

Serve the documentation locally using:

```bash
dbt docs serve --port 8081
```

The lineage graph shows an unbroken dependency chain from all three raw sources to `fct_daily_revenue`.

The project also declares an exposure named:

```text
executive_revenue_dashboard
```

which depends on `fct_daily_revenue`.

---

## Post-Hook and Read-Only Access

A marts-level post-hook is configured in `dbt_project.yml`.

After every marts model is built, dbt automatically executes a grant statement that provides `SELECT` access to:

```text
analytics_readonly
```

This ensures the read-only analytics role can query all marts models.

---

## Running the Project

### Validate the dbt setup

```bash
dbt debug
```

### Check source freshness

```bash
dbt source freshness
```

### Build the complete project

```bash
dbt build --full-refresh
```

### Run all tests

```bash
dbt test
```

### Generate documentation

```bash
dbt docs generate
```

### Serve documentation

```bash
dbt docs serve --port 8081
```

---

## Slim CI Runbook

Slim CI is used to build only modified dbt resources and their downstream dependencies instead of rebuilding the entire project for every pull request.

First, create a clean production-like baseline:

```bash
dbt build --full-refresh
```

The build generates a `manifest.json` file inside the `target` directory.

Save this manifest in a separate state directory so that later dbt commands do not overwrite the reference state:

```powershell
New-Item -ItemType Directory -Force state_prod
Copy-Item target\manifest.json state_prod\manifest.json
```

After making a model change, preview the resources dbt considers modified and their downstream dependencies:

```bash
dbt ls --select state:modified+ --state state_prod
```

Run Slim CI using:

```bash
dbt build --select state:modified+ --defer --state state_prod
```

`state:modified+` compares the current project with the saved reference manifest and selects modified resources together with their downstream dependencies.

`--defer` allows unchanged upstream dependencies to use relations represented by the saved production state.

The command output should be reviewed to confirm that only the modified model and its downstream dependencies were executed rather than the complete dbt DAG.

---
