README
===

It is very slow because of Vagrant. I don't know what to do with this. Stackoverflow answers haven't helped.
===

Setup
---

Config is located at `.env` file. It is generated after provision.  
Also you can copy it manually from `.env.example`
  
* LEVEL - Depth level  

Start
---
`vagrant up`

Manual start
---

It can be launched only from `Ubuntu` with `Ruby >= 2.0`

```
cp .env.example .env
bundle install  
bundle exec rackup -p 3000 -o 0.0.0.0 -P ./.pid -D  
bundle exec sidekiq -c 100 -C sidekiq.yml -r ./parser_worker.rb -L sidekiq.log -d  
```