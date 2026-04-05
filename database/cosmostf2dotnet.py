import sys,re
cfg = sys.stdin.read()
if not cfg.strip():
    print("Usage: cat cosmos_container.tf | tf2cosmosdotnet")
    raise SystemExit(1)

# Quick extraction of relevant fields from TF snippet
def get(val, pattern, default=None):
    m = re.search(pattern, val, re.MULTILINE)
    return m.group(1).strip().strip('"') if m else default

name            = get(cfg, r'name\s*=\s*"([^"]+)"')
pkpaths         = re.findall(r'partition_key_paths\s*=\s*\[([^\]]+)\]', cfg)
pkv             = get(cfg, r'partition_key_version\s*=\s*([0-9]+)', "1")
throughput      = get(cfg, r'throughput\s*=\s*([0-9]+)', "400")
idx_mode        = get(cfg, r'indexing_mode\s*=\s*"([^"]+)"', "consistent")
included        = re.findall(r'included_path\s*\{\s*path\s*=\s*"([^"]+)"', cfg)
excluded        = re.findall(r'excluded_path\s*\{\s*path\s*=\s*"([^"]+)"', cfg)
unique          = re.findall(r'unique_key {\n    paths\s*=\s*\[([^\]]+)\]', cfg)

pk_list = []
if pkpaths:
    content = pkpaths[0]
    pk_list = [p.strip().strip('"') for p in content.split(",") if p.strip()]
if not pk_list:
    pk_list = ["/definition/id"]

def _unique_key_policy(unique_paths_list):
    """Generate unique key policy code from regex matches."""
    if not unique_paths_list:
        return ''
    
    code = 'var uniqueKeyPolicy = new UniqueKeyPolicy();\n\n        '
    pathIndex = 0
    for match in unique_paths_list:
        paths = []
        for p in match.split(','):
            p_clean = p.strip().strip('"').strip()
            if p_clean:
                paths.append(p_clean)
        if paths:
            code += f'var uniqueKey{pathIndex} = new UniqueKey();\n        '
            for path in paths:
                code += f'uniqueKey{pathIndex}.Paths.Add("{path}");\n        '
            code += f'uniqueKeyPolicy.UniqueKeys.Add(uniqueKey{pathIndex});\n\n        '
            pathIndex += 1
    return code.rstrip()

name = name or "container-id"

# Output code
indexing_policy_code = f"""var indexingPolicy = new IndexingPolicy
{{
    IndexingMode = IndexingMode.{idx_mode.capitalize()}
}};
{''.join([f'indexingPolicy.IncludedPaths.Add(new IncludedPath {{ Path = "{v}" }});\n' for v in included])}{''.join([f'indexingPolicy.ExcludedPaths.Add(new ExcludedPath {{ Path = "{v}" }});\n' for v in excluded])}"""

unique_policy_code = ''
if unique:
    unique_policy_code = 'var uniqueKeyPolicy = new UniqueKeyPolicy();\n'
    pathIndex = 0
    for match in unique:
        paths = []
        for p in match.split(','):
            p_clean = p.strip().strip('"').strip()
            if p_clean:
                paths.append(p_clean)
        if paths:
            unique_policy_code += f'var uniqueKey{pathIndex} = new UniqueKey();\n'
            for path in paths:
                unique_policy_code += f'uniqueKey{pathIndex}.Paths.Add("{path}");\n'
            unique_policy_code += f'uniqueKeyPolicy.UniqueKeys.Add(uniqueKey{pathIndex});\n'
            pathIndex += 1

pk_str = ', '.join([f'"{p}"' for p in pk_list])
container_properties_code = f'var containerProperties = new ContainerProperties(containerId, {f'"{pk_list[0]}"' if len(pk_list) == 1 else f'new[] {{ {pk_str} }}'});\ncontainerProperties.IndexingPolicy = indexingPolicy;\n'
if unique:
    container_properties_code += 'containerProperties.UniqueKeyPolicy = uniqueKeyPolicy;\n'

create_container_code = f'var containerResponse = await database.CreateContainerIfNotExistsAsync(containerProperties, throughput: {throughput});'

print(f"""// ---- generated from Terraform container block ----
#:package Microsoft.Azure.Cosmos@3.58.0
#:package Newtonsoft.Json@13.0.1

using Microsoft.Azure.Cosmos;

// Configure these with your target Cosmos DB details
var endpointUri = Environment.GetEnvironmentVariable("COSMOS_ACCOUNT_ENDPOINT") ?? throw new InvalidOperationException("Environment variable COSMOS_ACCOUNT_ENDPOINT is not set.");
var key = Environment.GetEnvironmentVariable("COSMOS_ACCOUNT_KEY") ?? throw new InvalidOperationException("Environment variable COSMOS_ACCOUNT_KEY is not set.");
var databaseId = Environment.GetEnvironmentVariable("COSMOS_DATABASE_ID") ?? throw new InvalidOperationException("Environment variable COSMOS_DATABASE_ID is not set.");
var containerId = Environment.GetEnvironmentVariable("COSMOS_CONTAINER_ID") ?? throw new InvalidOperationException("Environment variable COSMOS_CONTAINER_ID is not set.");

CosmosClientOptions options = new ()
{{
    ConnectionMode = ConnectionMode.Gateway,
}};

using CosmosClient client = new(endpointUri, key, options);

// Get or create the database
Database database = await client.CreateDatabaseIfNotExistsAsync(databaseId);
Console.WriteLine($"Database {{databaseId}} is ready.");

// Create the indexing policy
{indexing_policy_code}
// Create the unique key policy
{unique_policy_code}
// Create the container properties
{container_properties_code}
// Create the container
{create_container_code}
Console.WriteLine($"Container {{containerResponse.Resource.Id}} created successfully.");""")
