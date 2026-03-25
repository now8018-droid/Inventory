# d9_inventory Audit Report (2026-03-24)

## Scope
- Static audit of Lua source under `d9_inventory`.
- Focus: bugs, integration gaps, and systems that are not wired together.
- No runtime FiveM server/database was started in this environment.

## Critical Findings

### 1) Vehicle callback is implemented then overwritten later (feature break)
- `server/sv_keys.lua` correctly registers callback `GetName("callback", "Vehicle")` and queries `owned_vehicles`.
- `server/server.lua` registers **the same callback name again** and returns `cb({})`.
- In `fxmanifest.lua`, `server/server.lua` loads after `server/sv_keys.lua`, so the empty callback likely overrides the real one.
- Impact: vehicle key list in inventory can be empty even when player owns vehicles.

### 2) Client and server event names are inconsistent (events never meet)
- Client listens on:
  - `esx_inventoryhud:GetAccessories`
  - `esx_inventoryhud:GetVehicleKey`
- Server emits on player load:
  - `esx_inventoryhud:getOwnerVehicle`
  - `esx_inventoryhud:getOwnerAccessories`
- Client also triggers server events `esx_inventoryhud:getOwnerVehicle` / `esx_inventoryhud:getOwnerAccessories`, but no matching server `RegisterNetEvent` handlers were found in this resource.
- Impact: initial sync paths for keys/accessories appear disconnected.

### 3) Vehicle model lookup callback is stubbed (key-trade logic blocked)
- `client/function.lua` (give item flow for `item_key`) calls callback `GetCurrentResourceName()..':getVehicleModelByPlate'` and requires non-nil model to continue.
- `server/ServerFunction.lua` currently always returns `cb(nil)`.
- Impact: key item transfer branch can fail and show “ไม่พบข้อมูลรถ.!!!!”.

### 4) Security hook validates but does not enforce transfer action
- `server/sv_security.lua` attaches `AddEventHandler(GetName("sv", "giveItem"), ...)` and validates transfer.
- After validation it only comments `-- โอนไอเทมตามปกติ...` and does not perform transfer.
- Another handler in `server/server.lua` performs transfer for the same event.
- Impact: duplicated handler architecture increases risk of partial refactor / policy bypass and makes behavior harder to reason about.

## Medium Findings

### 5) Accessory system callback has placeholder implementation
- `server/server.lua` callback `GetName("callback", "Accessories")` always returns `{}` with comment to integrate clothing/mask system.
- Impact: accessory tab/state may be incomplete depending on expected upstream data.

### 6) Missing in-resource handler references suggest external dependency or dead code
- Event triggers/uses found without handler implementation in this resource:
  - `esx_inventoryhud:DelAccessories`
  - `d9_inventory:lockVehicle` (client receiver not found here)
- Impact: if these are not provided by another resource, functions will silently not work.

## Recommended Integration Order
1. Remove duplicate callback registration in `server/server.lua` for `callback:Vehicle`, or rename and route to `sv_keys.lua` implementation.
2. Normalize event names (single canonical naming/casing) between client emit/listen and server emit/listen for owner vehicle/accessories sync.
3. Implement `:getVehicleModelByPlate` in `server/ServerFunction.lua` against `owned_vehicles` so key transfer flow can resolve model.
4. Consolidate `sv:giveItem` pipeline into one authoritative handler; keep security as pre-check utility (or middleware style) to avoid split logic.
5. Implement accessory callback/data contract and verify update events (`setmask`, refresh trigger) end-to-end.
6. Verify external dependencies and add notes in README/fxmanifest comments for required companion resources/events.

## Checks Executed
- `rg --files` (inventory file map)
- `rg -n` searches for callback/event wiring and placeholder markers
- Manual inspection of:
  - `fxmanifest.lua`
  - `client/client.lua`
  - `client/function.lua`
  - `server/server.lua`
  - `server/sv_keys.lua`
  - `server/ServerFunction.lua`
  - `server/sv_security.lua`

## Environment Limitations
- `luac` is not installed in this container, so syntax-check compile pass could not be executed.
- No live FiveM runtime + database in this environment, so findings are static-code based.
