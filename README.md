# Products API

A small Rails API I built to actually learn Rails instead of just reading about it. It's a products catalog with categories, JWT auth, and a background job — basic CRUD plus a few things that show I understand how the pieces fit together, not just how to scaffold a resource.

## Why I built this

I hadn't touched Ruby or Rails before this. Rather than doing a plain CRUD tutorial, I picked one small domain (products + categories) and pushed a bit further on a few things that actually come up in real Rails apps: N+1 queries, background jobs, and token auth.

## Stack

- Ruby 3.4.4 / Rails 8.1.3 (API-only mode)
- PostgreSQL
- Sidekiq + Redis for background jobs
- JWT for auth (bcrypt for password hashing)
- RSpec for tests

## Setup

You'll need Ruby 3.4+, PostgreSQL, and Redis running locally.

    bundle install
    bin/rails db:create
    bin/rails db:migrate
    bin/rails db:seed

Run the app (two processes, two terminals):

    bin/rails server -p 3001
    bundle exec sidekiq

## Endpoints

| Method | Path | Auth required | Description |
|---|---|---|---|
| GET | /products | No | List all products |
| GET | /products/:id | No | Get one product |
| POST | /products | Yes | Create a product |
| PATCH | /products/:id | Yes | Update a product |
| DELETE | /products/:id | Yes | Delete a product |
| GET | /categories | No | List categories |
| POST | /categories | No | Create a category |
| POST | /signup | No | Create a user, returns a JWT |
| POST | /login | No | Log in, returns a JWT |

## Try it out

Sign up and grab a token:

    curl -X POST http://localhost:3001/signup -H "Content-Type: application/json" -d '{"email":"you@example.com","password":"password123"}'

Create a category (needed before you can add a product):

    curl -X POST http://localhost:3001/categories -H "Content-Type: application/json" -d '{"category":{"name":"Electronics"}}'

Create a product (needs the token from signup):

    curl -X POST http://localhost:3001/products -H "Content-Type: application/json" -H "Authorization: Bearer YOUR_TOKEN_HERE" -d '{"product":{"name":"Widget","description":"A basic widget","price":9.99,"stock":100,"category_id":1}}'

List products (no auth needed):

    curl http://localhost:3001/products

Update a product:

    curl -X PATCH http://localhost:3001/products/1 -H "Content-Type: application/json" -H "Authorization: Bearer YOUR_TOKEN_HERE" -d '{"product":{"price":12.99}}'

Delete a product:

    curl -X DELETE http://localhost:3001/products/1 -H "Authorization: Bearer YOUR_TOKEN_HERE"

## The N+1 fix

This is the part I actually spent time on. `GET /products` originally loaded every product's category with a separate query — 10 products meant 11 total queries. Fixed it with `Product.includes(:category)`, which batches the category lookups into a single `IN (...)` query.

Before (11 queries):

    Product Load  SELECT "products".* FROM "products"
    Category Load  SELECT ... WHERE "categories"."id" = 2 LIMIT 1
    Category Load  SELECT ... WHERE "categories"."id" = 1 LIMIT 1
    Category Load  SELECT ... WHERE "categories"."id" = 3 LIMIT 1
    ... (repeated per row)

After (2 queries):

    Product Load  SELECT "products".* FROM "products"
    Category Load  SELECT ... WHERE "categories"."id" IN (2, 1, 3)

## Background job

Creating a product enqueues a `ProductNotifierJob` through Sidekiq instead of doing the "send a notification" work inline in the request. The controller just calls `perform_later` and returns right away — the actual job runs async, picked up by a separate Sidekiq worker process backed by Redis.

    INFO Sidekiq: Performing ProductNotifierJob with arguments: 12
    INFO Sidekiq: [ProductNotifierJob] Notification sent for new product: Gadget (#12)
    INFO Sidekiq: Performed ProductNotifierJob in 121ms

## Auth

JWT-based. Sign up or log in to get a token, then pass it as `Authorization: Bearer <token>` on any write request (create/update/delete). Reads (GET) are public. Tokens expire after 24 hours.

Tried without a token:

    curl -X POST http://localhost:3001/products -d '{"product":{"name":"NoAuth"}}'
    → 401 {"error":"Unauthorized"}

With a valid token:

    → 201 {"id":13,"name":"AuthedProduct",...}

## Tests

    bundle exec rspec

13 examples covering model validations/associations and request specs for the full CRUD + auth flow (unauthorized requests, invalid params, 404s, etc).

## What I'd add next

- Pagination on the index endpoint
- Rate limiting on signup/login
- Swap the notifier job for a real email via ActionMailer
- Docker Compose to spin up Postgres + Redis together instead of installing them locally
