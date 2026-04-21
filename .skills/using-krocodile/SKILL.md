---
name: using-krocodile
description: "Krocodile resource authoring reference. Load when writing or reviewing krocodile YAML."
---

# Using Krocodile

Krocodile is a Kubernetes composition system. Declare resources and their
relationships in a Graph; krocodile continuously reconciles them. All types
use API group `experimental.kro.run/v1alpha1`.

## Graph

The core primitive. A **namespace-scoped** resource that owns a set of
Kubernetes resources. Create a Graph and its resources are created. Delete
it and they cascade-delete.

A Graph's `spec.nodes` is a list of nodes. Each node has a unique `id`
(no hyphens, DNS-safe) and exactly one body keyword (`template`, `patch`,
`ref`, `watch`, or `def`). Nodes reference each other by `id` in CEL
expressions — this forms the dependency graph.

```yaml
apiVersion: experimental.kro.run/v1alpha1
kind: Graph
metadata:
  name: my-app
  namespace: default
spec:
  nodes:
    - id: deployment
      template:
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: my-app
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: my-app
          template:
            metadata:
              labels:
                app: my-app
            spec:
              containers:
                - name: app
                  image: nginx
    - id: service
      template:
        apiVersion: v1
        kind: Service
        metadata:
          name: ${deployment.metadata.name}-svc
        spec:
          selector: ${deployment.spec.selector.matchLabels}
          ports:
            - port: 80
```

## Node Types

Each node has exactly one body keyword. These are mutually exclusive.
`template`, `patch`, and `def` also accept a CEL string as the entire
body (e.g., `template: "${expr}"`) — the expression must evaluate to
the expected map at runtime. `ref` and `watch` accept only maps.

### template

Create and own a Kubernetes resource. Full server-side apply. The resource
is deleted when the Graph is deleted. Add annotation `kro.run/apply: Force`
to take ownership of contested fields from another actor (only valid on
template nodes).

```yaml
- id: deployment
  template:
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-app
    spec:
      replicas: 3
      # ...
```

### patch

Partial server-side apply on a resource you don't own. Only the declared
fields are managed. Fields are released on prune; the resource itself is
never deleted. Requires `metadata.name` (targets a specific resource).

```yaml
- id: status
  patch:
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: my-config
      namespace: default
    data:
      lastApplied: ${deployment.metadata.creationTimestamp}
```

### ref

Read-only reference to a single existing resource. Watches the target
reactively — re-reconciles when it changes in the cluster. Brings it
into scope so other nodes can reference its fields. Does not create,
modify, or delete the resource. Only `apiVersion`, `kind`, and
`metadata.{name, namespace}` are allowed — no other fields.

```yaml
- id: config
  ref:
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: app-config
      namespace: default
```

### watch

Observe a collection of resources reactively. Re-reconciles when
resources matching the selector are added, removed, or changed.
`metadata.name` is forbidden — for a single named resource, use `ref`.
An empty selector `{}` matches everything.

The node's scope value is a list of the matched resources.

```yaml
# All namespaces with a specific label
- id: namespaces
  watch:
    apiVersion: v1
    kind: Namespace
    metadata:
      selector:
        matchLabels:
          env: production

# All instances of a kind (empty selector = everything)
- id: webapps
  watch:
    apiVersion: experimental.kro.run/v1alpha1
    kind: WebApp
    metadata:
      selector: {}
```

### def

Computed values. No Kubernetes resource created. Injects data into scope
for other nodes to reference. Arbitrary keys allowed, but `apiVersion`
and `kind` are forbidden (def is not a resource).

```yaml
- id: labels
  def:
    app: ${config.data.appName}
    version: ${config.data.version}
    managed-by: krocodile
```

### Scope Values

Each node type produces a specific shape in scope when referenced by
other nodes via `${nodeId}`:

| Node type | Scope shape | Example access |
|-----------|-------------|----------------|
| `template` | Full resource object (as applied in-cluster) | `${deployment.status.availableReplicas}` |
| `patch` | Full resource object (as read from cluster) | `${status.metadata.resourceVersion}` |
| `ref` | Full resource object (as read from cluster) | `${config.data.version}` |
| `watch` | List of resource objects | `${webapps}` (use with `forEach`) |
| `def` | The computed map | `${labels.version}` |

Data becomes available in scope once the node's operation completes
(SSA apply, cluster read, or def evaluation). Downstream nodes that
reference it are evaluated after, in dependency order.

### Namespace Targeting

Template and patch nodes can target any namespace by setting
`metadata.namespace` explicitly. If omitted, resources default to the
Graph's namespace. This enables cross-namespace patterns like the
complete example, which creates resources in watched tenant namespaces.

## CEL Expressions

Expressions use `${...}` syntax. Reference other nodes by their `id`.

**Standalone** — The entire field value is a single `${expr}`. Preserves
the CEL return type (number, boolean, map, list).

```yaml
replicas: ${schema.spec.replicas}                    # integer
selector: ${deployment.spec.selector.matchLabels}    # map
```

**Embedded** — Mixed with literal text. Always produces a string.

```yaml
name: ${schema.metadata.name}-svc
image: nginx:${config.data.version}
```

**Deferred** — `$${expr}` strips one `$`, producing literal `${expr}` in
the output. Used in nested Graphs so the inner Graph evaluates the
expression at its own scope.

```yaml
# Outer Graph stamps an inner Graph.
# $${...} becomes ${...} in the child Graph's spec.
name: $${schema.metadata.name}
```

Three nesting levels: `${...}` (this Graph), `$${...}` (child Graph),
`$$${...}` (grandchild Graph).

### Custom Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `plural(s)` | string | English pluralization. `plural("WebApp").lowerAscii()` → `"webapps"` |
| `.ready()` | bool | True when the node is applied and its readyWhen conditions pass |
| `.updated()` | bool | True when the node is on the latest graph generation |
| `.dependencies()` | list | Scope values of all dependency nodes |
| `simpleSchema.toOpenAPI(schema, resources)` | map | Converts SimpleSchema to OpenAPI v3 for CRD generation |

Standard Kubernetes CEL extensions are also available: string manipulation,
list operations, regex, quantities, optional types, IP/CIDR, semver,
base64 encoding, JSON marshal/unmarshal, hashing (FNV-64a, SHA-256), and
random string generation.

### Scoping Rules

CEL scope is flat — any node can reference any other node by `id` in
expressions. At compile time, all node IDs are declared as variables.
At eval time, values are populated in dependency order (topological sort
of the DAG). If a node references another node, it implicitly depends
on it and will be evaluated after it.

- **Cycles are detected at compile time** and rejected.
- **`propagateWhen` cannot self-reference** — it is an input gate
  evaluated before the node, so the node's own data is unavailable.
- If a referenced node hasn't produced data yet (inflight, skipped),
  the expression gets a "pending" error and the node retries.

## Node Modifiers

Optional fields that can be added to any node alongside the body keyword.

### forEach

Expand the node once per item in a collection. The key is the loop
variable name; the value is a CEL expression evaluating to a list.
Exactly one variable. The variable name must not collide with any node
`id` in the graph. Works with all node types — `template`, `patch`, and
`def` are the common combinations. `forEach` + `def` produces a list
of computed values in scope.

The iteration variable has the same shape as a single element of the
source list. If iterating over a `watch` node, each item is a full
resource object. The variable is only accessible inside the forEach
node's own body and modifiers.

```yaml
- id: quotas
  forEach:
    ns: ${tenants}
  template:
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      name: default-quota
      namespace: ${ns.metadata.name}
    spec:
      hard:
        pods: "100"
```

### includeWhen

List of CEL conditions. All must be true or the node is skipped entirely,
along with any nodes that depend on it.

```yaml
- id: ingress
  includeWhen:
    - ${schema.spec.ingress.enabled}
  template:
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    # ...
```

### readyWhen

Override the default readiness check with explicit CEL conditions.
readyWhen is a health signal — it feeds the node's `.ready()` function
and the Graph's overall Ready condition, but it does **not** gate
dependency resolution. Downstream nodes can proceed as soon as the
resource is applied, regardless of readyWhen status.

```yaml
- id: deployment
  readyWhen:
    - ${deployment.status.availableReplicas == deployment.spec.replicas}
  template:
    apiVersion: apps/v1
    kind: Deployment
    # ...
```

### propagateWhen

Gate node evaluation. When unsatisfied, the node retains its last-applied
state rather than being re-evaluated. Enables rollout control
(exponential, linear, dependency-gated).

```yaml
- id: canary
  propagateWhen:
    - ${stable.ready()}
  template:
    apiVersion: apps/v1
    kind: Deployment
    # ...
```

### finalizes

Create a resource during teardown of another node. The finalizer node
must reach its readyWhen before the target node's resource is removed.
Use this for backup-before-delete patterns.

```yaml
- id: snapshot
  finalizes: volume
  readyWhen:
    - ${snapshot.status.readyToUse == true}
  template:
    apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshot
    spec:
      source:
        persistentVolumeClaimName: ${volume.metadata.name}
```

## Standard Library

Three higher-level types built on Graph. Only the Graph and GraphRevision
CRDs are pre-installed; the stdlib types bootstrap themselves at startup.

### Kind

**Cluster-scoped.** Define a new Kubernetes Kind. Creates a CRD and a
per-instance controller Graph. The per-instance resource is available as
`schema` in node expressions.

`spec.schema` uses SimpleSchema syntax (see below) to define the CRD's
spec and status fields. Status fields are CEL expressions that project
values from managed resources.

```yaml
apiVersion: experimental.kro.run/v1alpha1
kind: Kind
metadata:
  name: webapp
spec:
  kind: WebApp
  group: experimental.kro.run
  version: v1alpha1
  schema:
    spec:
      image: string | default=nginx
      replicas: integer | default=1
      port: integer | default=80
    status:
      ready: ${deployment.status.availableReplicas == schema.spec.replicas}
  nodes:
    - id: deployment
      template:
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: ${schema.metadata.name}
        spec:
          replicas: ${schema.spec.replicas}
          selector:
            matchLabels:
              app: ${schema.metadata.name}
          template:
            metadata:
              labels:
                app: ${schema.metadata.name}
            spec:
              containers:
                - name: app
                  image: ${schema.spec.image}
    - id: service
      template:
        apiVersion: v1
        kind: Service
        metadata:
          name: ${schema.metadata.name}-svc
        spec:
          selector:
            app: ${schema.metadata.name}
          ports:
            - port: ${schema.spec.port}
```

### Decorator

**Cluster-scoped.** Watch all instances of an existing Kind and create a
sub-Graph per instance. The watched resource is available as `item` in
node expressions. For collections only — for a single resource, use a
`ref` node in a plain Graph.

```yaml
apiVersion: experimental.kro.run/v1alpha1
kind: Decorator
metadata:
  name: namespace-policies
spec:
  watch:
    apiVersion: v1
    kind: Namespace
    selector: {}
  nodes:
    - id: policy
      template:
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        metadata:
          name: default-deny
          namespace: ${item.metadata.name}
        spec:
          podSelector: {}
          policyTypes:
            - Ingress
```

### Singleton

**Namespace-scoped.** Declare a resource that should exist exactly once.
When multiple Singletons target the same resource (same GVK + namespace +
name), highest `priority` wins. Ties broken by name (lexicographic,
lowest wins).

```yaml
apiVersion: experimental.kro.run/v1alpha1
kind: Singleton
metadata:
  name: shared-config
spec:
  priority: 100
  template:
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: shared-config
      namespace: platform
    data:
      version: "2.0"
```

## SimpleSchema

The DSL for `Kind.spec.schema` fields. Syntax: `fieldName: type` or
`fieldName: type | modifier=value modifier=value`.

**Types:**

| Type | Syntax |
|------|--------|
| String | `name: string` |
| Integer | `replicas: integer` |
| Boolean | `enabled: boolean` |
| Arbitrary map | `values: object` |
| Array | `tags: "[]string"` (quote in YAML) |
| Nested object | Indent child fields under the field name |

**Modifiers** (pipe-separated after the type):

| Modifier | Example |
|----------|---------|
| `default=` | `image: string \| default=nginx` |
| `required=true` | `name: string \| required=true` |
| `minimum=` / `maximum=` | `replicas: integer \| minimum=1 maximum=10` |
| `minLength=` / `maxLength=` | `name: string \| minLength=3 maxLength=63` |
| `pattern=` | `email: string \| pattern=^[a-z]+@` |

**Status fields** use CEL expressions referencing node IDs:

```yaml
schema:
  spec:
    image: string | default=nginx
    replicas: integer | default=1 minimum=1 maximum=100
    ingress:
      enabled: boolean | default=false
      host: string
  status:
    ready: ${deployment.status.availableReplicas == schema.spec.replicas}
    endpoint: ${service.status.loadBalancer.ingress[0].hostname}
```

## Nested Graphs

A Graph can contain another Graph as a `template` node. The inner Graph
is persisted to the cluster and reconciled independently — it has its own
scope and resource lifecycle.

Use `$${}` for expressions that should be evaluated by the inner Graph,
not the outer one. The outer controller strips one `$`, producing `${}`
in the child's spec. There is no string re-scanning; each controller
evaluates exactly one pass on its own spec.

Common pattern: outer `watch` + `forEach` stamps one inner Graph per
item. The inner Graph uses a `ref` to read its specific item fresh
(reactive to spec changes, O(1) per instance).

```yaml
- id: items
  watch:
    apiVersion: experimental.kro.run/v1alpha1
    kind: WebApp
    metadata:
      selector: {}

- id: controllers
  forEach:
    item: ${items}
  template:
    apiVersion: experimental.kro.run/v1alpha1
    kind: Graph
    metadata:
      name: ${item.metadata.name}-controller
    spec:
      nodes:
        # Inner Graph reads its specific instance fresh
        - id: schema
          ref:
            apiVersion: experimental.kro.run/v1alpha1
            kind: WebApp
            metadata:
              name: ${item.metadata.name}
              namespace: ${item.metadata.namespace}

        # $${} is evaluated by the inner Graph
        - id: deployment
          template:
            apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: $${schema.metadata.name}
            spec:
              replicas: $${schema.spec.replicas}
              # ...

        # Patch status back to the instance (inner Graph doesn't own it)
        - id: status
          patch:
            apiVersion: experimental.kro.run/v1alpha1
            kind: WebApp
            metadata:
              name: $${schema.metadata.name}
              namespace: $${schema.metadata.namespace}
            status:
              ready: $${deployment.status.availableReplicas == deployment.spec.replicas}
```

## Status Conditions

Every Graph has two status conditions that surface errors:

**Compiled** — Is the spec valid? Set once at parse/compile time.

| Status | Reason | Meaning | Fix |
|--------|--------|---------|-----|
| True | Compiled | Spec is valid | — |
| False | ExpressionError | CEL expression failed to compile | Check CEL syntax, verify referenced node IDs exist |
| False | DependencyError | Circular dependency detected | Check for reference cycles between nodes |
| False | DeclarationError | Bad node shape, missing fields, etc. | Check each node has exactly one body keyword, required fields present |

**Ready** — Are all nodes converged? Rollup of per-node states.

| Status | Reason | Meaning | Fix |
|--------|--------|---------|-----|
| True | Ready | All nodes reconciled | — |
| Unknown | Pending | Waiting for upstream data | Node dependencies haven't produced data yet; usually transient |
| Unknown | NotReady | Applied but readyWhen not yet satisfied | Wait, or check readyWhen expressions |
| Unknown | Blocked | Dependency in error state | Fix the upstream node named in the message |
| False | Conflict | SSA field ownership contested (409) | Another actor owns the field; use `kro.run/apply: Force` on template or remove the conflicting field |
| False | Error | Client error (forbidden, validation, bad CEL) | Check RBAC, resource schema, or CEL expression correctness |
| False | SystemError | Server/infrastructure failure | Transient; check API server health |
| False | NotCompiled | Spec is invalid; nothing runs | See Compiled condition for details |

The `message` field names the specific nodes with errors and their
reasons. When compilation fails, the previous valid revision continues
reconciling — resources are not orphaned.

## Complete Example

A platform controller that enforces tenant policies across namespaces.
Uses all five node types, `forEach`, `includeWhen`, and both standalone
and embedded CEL expressions.

```yaml
apiVersion: experimental.kro.run/v1alpha1
kind: Graph
metadata:
  name: tenant-policies
  namespace: platform-system
spec:
  nodes:
    # ── Read platform configuration ─────────────────────────────
    - id: config
      ref:
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: platform-config
          namespace: platform-system

    # ── Compute shared labels from config ───────────────────────
    - id: labels
      def:
        managed-by: tenant-policies
        policy-version: ${config.data.policyVersion}

    # ── Watch all tenant namespaces ─────────────────────────────
    - id: tenants
      watch:
        apiVersion: v1
        kind: Namespace
        metadata:
          selector:
            matchLabels:
              platform.io/tenant: "true"

    # ── Per-namespace ResourceQuota ─────────────────────────────
    - id: quotas
      forEach:
        ns: ${tenants}
      template:
        apiVersion: v1
        kind: ResourceQuota
        metadata:
          name: tenant-quota
          namespace: ${ns.metadata.name}
          labels: ${labels}
        spec:
          hard:
            pods: ${config.data.maxPods}
            requests.cpu: ${config.data.maxCPU}
            requests.memory: ${config.data.maxMemory}

    # ── Per-namespace LimitRange ────────────────────────────────
    - id: limits
      forEach:
        ns: ${tenants}
      template:
        apiVersion: v1
        kind: LimitRange
        metadata:
          name: tenant-limits
          namespace: ${ns.metadata.name}
          labels: ${labels}
        spec:
          limits:
            - type: Container
              default:
                cpu: ${config.data.defaultCPULimit}
                memory: ${config.data.defaultMemoryLimit}
              defaultRequest:
                cpu: ${config.data.defaultCPURequest}
                memory: ${config.data.defaultMemoryRequest}

    # ── Per-namespace NetworkPolicy (conditional on config) ─────
    - id: networkPolicies
      forEach:
        ns: ${tenants}
      includeWhen:
        - ${config.data.networkPoliciesEnabled == "true"}
      template:
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        metadata:
          name: tenant-isolation
          namespace: ${ns.metadata.name}
          labels: ${labels}
        spec:
          podSelector: {}
          policyTypes:
            - Ingress
            - Egress
          ingress:
            - from:
                - namespaceSelector:
                    matchLabels:
                      kubernetes.io/metadata.name: ${ns.metadata.name}
          egress:
            - to:
                - namespaceSelector:
                    matchLabels:
                      kubernetes.io/metadata.name: kube-system
              ports:
                - port: 53
                  protocol: UDP

    # ── Annotate each namespace with enforcement status ─────────
    - id: enforcement
      forEach:
        ns: ${tenants}
      patch:
        apiVersion: v1
        kind: Namespace
        metadata:
          name: ${ns.metadata.name}
          labels: ${labels}
          annotations:
            platform.io/policies-applied: "true"
            platform.io/policy-version: tenant-policies/${config.data.policyVersion}
```

**What this Graph does:** reads platform config from a ConfigMap (`ref`),
computes shared labels (`def`), watches all namespaces labeled as tenants
(`watch`), then for each tenant namespace: creates a ResourceQuota and
LimitRange (`template` + `forEach`), conditionally creates a
NetworkPolicy (`includeWhen`), and annotates the namespace with
enforcement status (`patch` + `forEach`). Delete the Graph and all
managed ResourceQuotas, LimitRanges, and NetworkPolicies are cleaned up;
the patch fields on the Namespaces are released.
