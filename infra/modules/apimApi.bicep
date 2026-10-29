// One APIM API fronting the Function App, with two operations and a
// policy. The policy is the interesting part: APIM policies are XML
// executed in a fixed pipeline (inbound -> backend -> outbound ->
// on-error), and <base /> keeps the inherited policy chain intact.
//
// This policy does three things on every request:
//   1. Rate-limits each caller IP to 100 calls per minute.
//   2. Allows cross-origin calls from any origin (demo only — lock
//      this down to your frontend's domain in production).
//   3. Strips the subscription key requirement? No — it deliberately
//      does NOT: APIM's default subscription key stays required, so
//      anonymous traffic cannot reach the function at all.

param apimName string
param functionHostName string

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimName
}

resource api 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apim
  name: 'greeting-api'
  properties: {
    displayName: 'Greeting API'
    description: 'Demo API fronting the greeting Function App.'
    path: 'greeting'
    protocols: [
      'https'
    ]
    // Calls to https://<apim>/greeting/* are forwarded to the function.
    serviceUrl: 'https://${functionHostName}/api'
  }
}

resource healthOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: api
  name: 'health'
  properties: {
    displayName: 'Health check'
    method: 'GET'
    urlTemplate: '/health'
  }
}

resource greetOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: api
  name: 'greet'
  properties: {
    displayName: 'Greet a name'
    method: 'GET'
    urlTemplate: '/greet'
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    format: 'xml'
    value: '''
<policies>
  <inbound>
    <base />
    <rate-limit-by-key calls="100" renewal-period="60" counter-key="@(context.Request.IpAddress)" />
    <cors allow-credentials="false">
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
'''
  }
}
