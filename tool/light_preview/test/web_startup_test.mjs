import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

const html = await readFile(new URL('../web/index.html', import.meta.url), 'utf8');
const startup = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const scope = 'http://127.0.0.1:8765/';
const oldWorker = { scriptURL: `${scope}flutter_service_worker.js?v=old` };

async function run({ registration = null, controller = null } = {}) {
  const result = { unregisters: 0, reloads: 0, scripts: [] };
  if (registration) {
    registration.unregister = async () => { result.unregisters++; return true; };
  }
  await vm.runInNewContext(startup, {
    URL,
    console,
    navigator: { serviceWorker: {
      controller,
      getRegistration: async (requestedScope) => {
        assert.equal(requestedScope, scope);
        return registration;
      },
    } },
    location: { reload: () => result.reloads++ },
    document: {
      baseURI: scope,
      createElement: () => ({}),
      body: { appendChild: (script) => result.scripts.push(script.src) },
    },
  });
  return result;
}

assert.deepEqual(await run({ registration: { scope, active: oldWorker }, controller: oldWorker }),
  { unregisters: 1, reloads: 1, scripts: [] });
// With the worker unregistered, the next page load starts the app directly.
assert.deepEqual(await run(),
  { unregisters: 0, reloads: 0, scripts: [`${scope}flutter_bootstrap.js`] });
// Neither another application's worker nor a differently scoped worker is touched.
for (const registration of [
  { scope, active: { scriptURL: `${scope}another-app-worker.js` } },
  { scope: `${scope}another-app/`, active: oldWorker },
]) {
  assert.deepEqual(await run({ registration, controller: oldWorker }),
    { unregisters: 0, reloads: 0, scripts: [`${scope}flutter_bootstrap.js`] });
}
assert.deepEqual(await run({ registration: { scope, active: oldWorker } }),
  { unregisters: 1, reloads: 0, scripts: [`${scope}flutter_bootstrap.js`] });
console.log('Local service-worker migration checks passed.');
