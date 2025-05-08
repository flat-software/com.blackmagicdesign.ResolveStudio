import {serve} from "@hono/node-server";
import {Hono} from "hono";
import {HTTPException} from "hono/http-exception";
import {logger} from "hono/logger";
import {getDownload, getLatestVersion} from "./fetch.ts";
import {Branch} from "./model.ts";

const app = new Hono();
app.use(logger());

app.get("/info", c => {
  return c.text("Server is running!\n");
});

app.get("/version/:branch", async c => {
  const branch = c.req.param("branch") === "beta" ? Branch.BETA : Branch.STABLE;
  const latestVersion = await getLatestVersion(branch);
  if (!latestVersion) {
    throw new HTTPException(404, {message: "Version not found."});
  }

  return c.json({
    url: `http://localhost:5173/download/${latestVersion.downloadId}`,
  });
});

app.get("/download/:downloadId", async c => {
  const {downloadId} = c.req.param();
  const response = await getDownload(downloadId);
  if (!response) {
    throw new HTTPException(404, {message: "Download not found."});
  }

  const headers = new Headers(response.headers);
  headers.set("content-disposition", 'attachment; filename="resolve.zip"');

  return new Response(response.body, {headers});
});

serve({
  fetch: app.fetch,
  port: 5173,
});
