import type {Version} from "./model.ts";
import {Branch} from "./model.ts";

const headers = {
  "accept": "application/json, text/plain, */*",
  "origin": "https://www.blackmagicdesign.com",
  "user-agent":
    "Mozilla/5.0 (X11; Linux) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.75 Safari/537.36",
  "content-type": "application/json;charset=UTF-8",
  "accept-encoding": "gzip, deflate, br",
  "accept-language": "en-US,en;q=0.9",
  "authority": "www.blackmagicdesign.com",
  "cookie": "_ga=GA1.2.1849503966.1518103294; _gid=GA1.2.953840595.1518103294",
  "referer":
    "https://www.blackmagicdesign.com/support/download/77ef91f67a9e411bbbe299e595b4cfcc/Linux",
};

export async function getLatestVersion(
  branch: Branch
): Promise<Version | undefined> {
  const bmdBranch =
    branch === Branch.BETA ? "latest-version" : "latest-stable-version";

  const response = await fetch(
    `https://www.blackmagicdesign.com/api/support/${bmdBranch}/davinci-resolve-studio/linux`,
    {headers}
  );

  if (!response.ok) {
    return undefined;
  }

  const responseJson = (await response.json()) as any;

  const major = responseJson?.linux?.major;
  const minor = responseJson?.linux?.minor;
  const patch = responseJson?.linux?.releaseNum;
  const build = responseJson?.linux?.build;

  const rawBeta = responseJson?.linux?.beta;
  const beta = Number.isSafeInteger(rawBeta) ? rawBeta : undefined;

  const releaseId = String(responseJson?.linux?.releaseId);
  const downloadId = String(responseJson?.linux?.downloadId);

  if (
    !Number.isSafeInteger(major) ||
    !Number.isSafeInteger(minor) ||
    !Number.isSafeInteger(patch) ||
    !Number.isSafeInteger(build) ||
    !releaseId ||
    !downloadId
  ) {
    return undefined;
  }

  return {
    major,
    minor,
    patch,
    build,
    beta,
    releaseId,
    downloadId,
  };
}

export async function getDownload(downloadId: string) {
  const url = `https://www.blackmagicdesign.com/api/register/us/download/${downloadId}`;
  const downloadUrlResponse = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify({
      firstname: "Flatpak",
      lastname: "Builder",
      email: "flatpak@blackmagicdesign.com",
      phone: "408-954-0500",
      country: "us",
      state: "California",
      city: "Burbank",
      street: "333 N. Glenoaks Boulevard",
      product: "DaVinci Resolve",
    }),
  });

  if (!downloadUrlResponse.ok) {
    throw new Error("Download URL request failed.");
  }

  const downloadUrl = await downloadUrlResponse.text();
  if (!downloadUrl) {
    throw new Error("Download URL not found.");
  }

  const downloadResponse = await fetch(downloadUrl);
  const downloadBody = downloadResponse.body as ReadableStream<Uint8Array>;
  if (!downloadResponse.ok || !downloadBody) {
    throw new Error("Download request failed.");
  }

  return downloadResponse;
}
