
/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const express = require("express")
const bodyParser = require("body-parser")
const vm = require('vm')

const app = express()
app.use(bodyParser.json())

// Check environment for filter expression
if (!process.env.FILTER) {
    console.error("environment variable FILTER is missing.")
    process.exit(1)
}

const code = `(${process.env.FILTER})`

let script
try {
   script = new vm.Script(code)
} catch (e) {
  console.error('invalid code')
  console.log(code)
  process.exit(1)
}

const cloudevent = req => {
  const event = {data: req.body}
  for (const key in req.headers) {
    if (key.startsWith('ce-')) {
      event[key.substr(3)] = req.headers[key]
    }
  }
  return event
}

app.post('/', (req, res) => {
  console.log('receiving Cloud Event')
  const event = cloudevent(req)
  console.log(JSON.stringify(event, null, 2))

  try {
    const b = script.runInNewContext({event, env: process.env})

    if (b) {
      res.header(req.headers).status(200).send(req.body)
    } else {
      res.status(200).end()
    }
  } catch (e) {
    res.header(req.headers).status(200).send({error: e.message})
  }
})

app.listen(8080)