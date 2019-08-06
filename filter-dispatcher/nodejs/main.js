
/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the 'License'); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const fs = require('fs')
const express = require('express')
const bodyParser = require('body-parser')
const vm = require('vm')

const app = express()
app.use(bodyParser.json())

// Read config file
let config
try {
  config = fs.readFileSync('/etc/config.json')
} catch (e) {
  console.error('error reading config file')
  console.log(e)
  process.exit(1)
}

let svcs
try {
  svcs = JSON.parse(config)
} catch (e) {
  console.error('error parsing the config file')
  console.log(e)
  process.exit(1)
}

let scripts = {}
for (const host in svcs) {
  console.log(`adding ${host}`)
  let entry
  try {
    entry = JSON.parse(svcs[host])
  } catch (e) {
    console.error(`error parsing ${host} configuration`)
    console.log(e)
    process.exit(1)
  }

  if (!entry.hasOwnProperty('expression')) {
    console.error(`missing expression in ${JSON.stringify(entry, null, 2)}`)
    process.exit(1)
  }

  try {
    scripts[host] = new vm.Script(entry.expression)
  } catch (e) {
    console.error(`invalid expression ${entry.expression}`)
    console.log(e)
    process.exit(1)
  }
}

const cloudevent = req => {
  const event = { data: req.body }
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
  console.log(req.headers.host)
  try {
    const b = scripts[req.headers.host].runInNewContext({ event, env: process.env })

    if (b) {
      res.header(req.headers).status(200).send(req.body)
    } else {
      res.status(200).end()
    }
  } catch (e) {
    res.header(req.headers).status(200).send({ error: e.message })
  }
})

app.listen(8080)