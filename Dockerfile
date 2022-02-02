ARG RELEASE_NAME="hello_cluster_main"

ARG ELIXIR_VERSION="1.13.2"
ARG ERLANG_VERSION="24.2.1"
ARG ALPINE_VERSION="3.15.0"

ARG BUILDER_IMAGE="hexpm/elixir:$ELIXIR_VERSION-erlang-$ERLANG_VERSION-alpine-$ALPINE_VERSION"
ARG RUNNER_IMAGE="alpine:$ALPINE_VERSION"

FROM $BUILDER_IMAGE as builder

ARG RELEASE_NAME

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"

RUN mkdir -p apps/$RELEASE_NAME

COPY mix.exs mix.lock ./
COPY apps/$RELEASE_NAME/mix.exs apps/$RELEASE_NAME
RUN mix deps.get --only $MIX_ENV

COPY config config
RUN mix deps.compile

COPY apps/$RELEASE_NAME/lib apps/$RELEASE_NAME/lib

RUN mix compile --warnings-as-errors

COPY rel rel
RUN mix release $RELEASE_NAME

FROM $RUNNER_IMAGE

ARG RELEASE_NAME

RUN apk add --no-cache \
    libgcc \
    libstdc++ \
    ncurses

RUN addgroup -g 1000 hello_cluster && \
    adduser -D -h /app -G hello_cluster -u 1000 hello_cluster

USER hello_cluster:hello_cluster
WORKDIR /app

COPY --from=builder --chown=hello_cluster:hello_cluster \
     /app/_build/prod/rel/$RELEASE_NAME/ ./

RUN ln -s /app/bin/$RELEASE_NAME /app/bin/server


ENTRYPOINT ["/app/bin/server"]
CMD ["start"]
