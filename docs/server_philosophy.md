# **Server Philosophy**

***DartZen Ecosystem***

## 🎯 Purpose of the Server**

`dartzen_server` is an application boundary, not business logic and not infrastructure.

The server exists to:

* receive external signals,
* translate them into domain calls,
* return domain results back to the outside world.

The server does not make decisions.  
The server does not own meaning.  
The server is not a source of truth.  
The source of truth is the domain.

## 🔀 Server Is Not a Protocol

HTTP, gRPC, WebSocket, background jobs, cron — these are delivery mechanisms, not the server itself.

`dartzen_server`:

* is not modeled around HTTP,
* is not bound to a specific transport,
* does not use protocol terminology inside domain boundaries. 
* does not use protocol terminology inside domain boundaries.

Protocols are adapters.  
The server is the stage on which adapters appear and disappear.

## 🔢 Server and Domain

The server:

* invokes domain use cases,
* passes domain value objects,
* receives `ZenResult`.

The server does not:

* validate business invariants,
* decide what is allowed,
* understand identity lifecycle beyond what the contract exposes.

Any logic that can exist without the server must live outside the server.

## ⚙️ Server and Infrastructure

Infrastructure adapters:

* Firestore  
* Identity Toolkit  
* Cache
* Mail  
* Background jobs

**do not know about:**

* each other,
* transport,
* UI,
* the server as a whole.

The server is the only place where orchestration is allowed:

* call ordering,
* adapter coordination,
* fallback and degradation.

Infrastructure is detail.  
The server is a coordinator, not a thinker.

## 🤖 Identity Toolkit Is Not Identity

External authentication systems:

* are not identity,  
* do not own identity state,  
* do not define authority.

They provide signals.

Mapping is always:

* `external auth signal → domain identity transition`

Never the other way around.

## 📊 Errors and Results

The server:

* does not create domain errors,
* does not reinterpret their meaning,
* does not replace them with protocol-specific semantics.

Its responsibility is to:

* translate `ZenResult` into transport-friendly forms,
* preserve structure and semantic intent.

Errors are part of the contract, not an implementation detail.

## 📱 UI and Stubs

UI and auth flows implemented using stubs:

* are considered valid,
* reflect the domain model,
* do not require revision when the server is introduced.

The server must adapt to already verified meaning, not redefine it.

## 📝 Responsibility Boundary (Summary)

The server is responsible for:

* orchestration,
* application lifecycle,
* adapter wiring,
* result delivery.
* adapter wiring,
* result delivery.

**The server is not responsible for:**

* business meaning,
* rules,
* domain decisions,
* long-lived data models.

## 🧘🏻 Zen Principle

**If the server disappears,**  
**the domain must continue to exist without pain.**

**If the domain cannot be imagined without the server,**  
**the boundary has already been violated.**
