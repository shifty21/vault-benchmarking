-- Script that writes secrets to k/v engine in Vault
-- You can specify the number of distinct secrets to write by adding "-- <N>" after the URL

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
   requests  = 0
   writes = 0
   responses = 0
   method = "POST"
   -- give each thread different random seed
   math.randomseed(os.time() + id*1000)
   local msg = "thread %d created"
   print(msg:format(id))
end

function request()
   writes = writes + 1
   -- randomize path to secret
   path = "/v1/secret/write-random-test-" .. math.random(num_secrets)
   -- minimal secret giving thread id and # of write
   -- body = '{"foo-' .. id .. '" : "bar-' .. writes ..'"}'
   -- add extra key with 100 bytes
   body = '{"thread-' .. id .. '" : "write-' .. writes ..'","extra" : "1xxxxxxxxx2xxxxxxxxx3xxxxxxxxx4xxxxxxxxx5xxxxxxxxx6xxxxxxxxx7xxxxxxxxx8xxxxxxxxx9xxxxxxxxx0xxxxxxxxx"}'
   requests = requests + 1
   return wrk.format(method, path, nil, body)
end

function response(status, headers, body)
   responses = responses + 1
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
      thread:get("writes")          -- total writes during the benchmark
      ))
   end
end
