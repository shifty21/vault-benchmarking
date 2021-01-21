-- Script that reads secrets from k/v engine in Vault
-- To indicate the number of secrets you want to read, add "-- <N>" after the URL
-- If you want to print secrets read, add "-- <N> true" after the URL

json = require "json"

local counter = 1
local threads = {}

function setup(thread)
   thread:set("id", counter)
   table.insert(threads, thread)
   counter = counter + 1
end

function init(args)
   if args[1] == nil then
      num_secrets = 1000
   else
      num_secrets = tonumber(args[1])
   end
   print("Number of secrets is: " .. num_secrets)
   if args[2] == nil then
      print_secrets = "false"
   else
      print_secrets = args[2]
   end
   requests  = 0
   reads = 0
   responses = 0
   method = "GET"
   body = ''
   -- give each thread different random seed
   math.randomseed(os.time() + id*1000)
   local msg = "thread %d created with print_secrets set to %s"
   print(msg:format(id, print_secrets))
end

function request()
   reads = reads + 1
   -- randomize path to secret
   path = "/v1/secret/read-test/secret-" .. math.random(num_secrets)
   requests = requests + 1
   return wrk.format(method, path, nil, body)
end

function response(status, headers, body)
   responses = responses + 1
   if print_secrets == "true" then
      body_object = json.decode(body)
      for k,v in pairs(body_object) do 
         if k == "data" then
            print("Secret path: " .. path)
            for k1,v1 in pairs(v) do
               local msg = "read secrets: %s : %s"
               print(msg:format(k1, v1)) 
            end
         end
      end
   end 
end

function done(summary, latency, requests)
   for index, thread in ipairs(threads) do
      print(string.format("%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",
      latency.min,    -- minimum latency
      latency.max,    -- max latency
      latency.mean,   -- mean of latency
      latency.stdev,  -- standard deviation of latency
      latency:percentile(50),     -- 50percentile latency
      latency:percentile(90),     -- 90percentile latency
      latency:percentile(99),     -- 99percentile latency
      latency:percentile(99.999), -- 99.999percentile latency
      summary["duration"],          -- duration of the benchmark
      summary["requests"],          -- total requests during the benchmark
      summary["bytes"],             -- total received bytes during the benchmark
      summary["errors"]["connect"], -- total socket connection errors
      summary["errors"]["read"],    -- total socket read errors
      summary["errors"]["write"],   -- total socket write errors
      summary["errors"]["status"],  -- total socket write errors
      summary["errors"]["timeout"],  -- total request timeouts
      thread:get("responses"),          -- total responses during the benchmark
      thread:get("reads")          -- total writes during the benchmark
      ))
   end
end
