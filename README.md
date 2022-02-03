# HelloCluster

Распределённый Hello-сервис 👀

Дано: umbrella-проект с двумя приложениями:

* `hello_cluster_main` &mdash; предоставляет HTTP API, запущен в единственном экземпляре
  (можно запустить больше, но надо тогда ставить балансер);

* `hello_cluster_worker` &mdash; приложение-воркер, запускается в двух экземплярах,
  `hello_cluster_main` стартует на нём процессы.

HTTP API:

* `GET /greet` &mdash; запускает [stateless-процесс](apps/hello_cluster_worker/lib/hello_cluster_worker/stateless_worker.ex)
   на одной из нод-воркеров, который возвращает в главное приложение ответ и сразу завершается;

* `GET /greet/:name` &mdash; запускает [stateful-процесс](apps/hello_cluster_worker/lib/hello_cluster_worker/stateful_worker.ex)
   на одной из нод-воркеров, который возвращает в главное приложение ответ, считает количество
   вызовов и *завершается не сразу*, а после 10 секунд неактивности (т.е. если за этот период
   больше не было запросов `GET /greet/:name` с тем же самым `:name`).

# Запуск

## Через `nix run`

Если у вас стоит пакетный менеджер `nix` с включённой поддержкой flakes, то запустить
приложения можно без клонирования репозитория одной командой:

```sh
$ nix run github:smaximov/hello_cluster -- start
```

## Через `docker-compose`

Склонируйте репу и запустите `docker-compose` ¯\\\_(ツ)_/¯

# Пример

```sh
$ # stateless-воркер:
$ curl http://localhost:4000/greet
Hello from #PID<0.987.0> on hello_cluster_worker_1@K-1506!


$ # теперь он запущен на другой ноде (но мог запуститься и на той же):
$ curl http://localhost:4000/greet
Hello from #PID<0.979.0> on hello_cluster_worker_2@K-1506!


$ # stateful-воркер для имени john
$ curl http://localhost:4000/greet/john
  Hello to john from #PID<0.980.0> on hello_cluster_worker_2@K-1506!

  This server was called 1 time(s) and will shut down after 10000ms of inactivity.


$ # stateful-воркер с другим именем (mary) запущен на другой ноде:
$ curl http://localhost:4000/greet/mary
  Hello to mary from #PID<0.990.0> on hello_cluster_worker_1@K-1506!

  This server was called 1 time(s) and will shut down after 10000ms of inactivity.


$ # новое число вызовов (тот же самый процесс):
$ curl http://localhost:4000/greet/mary
  Hello to mary from #PID<0.990.0> on hello_cluster_worker_1@K-1506!

  This server was called 2 time(s) and will shut down after 10000ms of inactivity.


$ # stateful-воркер (mary) был остановлен по таймауту и перезапущен после нового запроса (другой pid):
$ sleep 10 && curl http://localhost:4000/greet/mary
  Hello to mary from #PID<0.993.0> on hello_cluster_worker_1@K-1506!

  This server was called 1 time(s) and will shut down after 10000ms of inactivity.
```
