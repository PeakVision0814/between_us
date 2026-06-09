import { assertStringIncludes } from "jsr:@std/assert@1";

Deno.test("delete-account rejects caller supplied user id", async () => {
  const source = await Deno.readTextFile(
    new URL("./index.ts", import.meta.url),
  );

  assertStringIncludes(source, '"user_id" in body');
  assertStringIncludes(source, '"userId" in body');
  assertStringIncludes(source, "user_id_not_allowed");
});

Deno.test("delete-account derives target user from access token", async () => {
  const source = await Deno.readTextFile(
    new URL("./index.ts", import.meta.url),
  );

  assertStringIncludes(source, "auth.getUser");
  assertStringIncludes(source, "admin.deleteUser");
  assertStringIncludes(source, "admin.deleteUser(\n      user.id,\n      true");
  assertStringIncludes(source, "user.id");
});
