import * as fs from "node:fs/promises";

//
// Model and constants.
//

interface Version {
  major: number;
  minor: number;
  patch: number;
  build: number;
  beta?: number;
  releaseId: string;
  downloadId: string;
}

const downloadedFilePath = "./resolve.zip";
const printProgressResolution = 500 * 1024; // 1MB;

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

//
// Helpers.
//

function formatVersion(version: Version) {
  const {major, minor, patch, build, beta} = version;
  const betaString = beta ? `Beta ${beta}` : "";
  return `${major}.${minor}.${patch} Build ${build} ${betaString}`;
}

async function fileExists(path: string) {
  try {
    await fs.access(path, fs.constants.F_OK);
    return true;
  } catch {
    return false;
  }
}

async function getLatestVersion(): Promise<Version | undefined> {
  const response = await fetch(
    "https://www.blackmagicdesign.com/api/support/latest-version/davinci-resolve-studio/linux",
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

async function downloadVersion(
  version: Version,
  writeToPath: string,
  onProgress: (loaded: number, total: number) => void
) {
  const url = `https://www.blackmagicdesign.com/api/register/us/download/${version.downloadId}`;
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

  let loadedBytes = 0;
  const totalBytes = Number(downloadResponse.headers.get("content-length"));

  onProgress(loadedBytes, totalBytes);

  let lastLoadedBytes = 0;
  const maybeOnProgress = () => {
    if (loadedBytes - lastLoadedBytes < printProgressResolution) {
      return;
    }

    lastLoadedBytes = loadedBytes;
    onProgress(loadedBytes, totalBytes);
  };

  const progressStream = new ReadableStream({
    start(controller) {
      const reader = downloadBody.getReader();

      const read = async () => {
        const {done, value} = await reader.read();
        if (done) {
          controller.close();
          return;
        }

        loadedBytes += value.byteLength;
        maybeOnProgress();
        controller.enqueue(value);
        read();
      };
      read();
    },
  });

  await fs.writeFile(writeToPath, progressStream);
}

//
// Program flow.
//

// Check if the file was already downloaded.
if (await fileExists(downloadedFilePath)) {
  console.log("Resolve was already downloaded.");
  process.exit(0);
}

// Otherwise, check the current version.
const version = await getLatestVersion();
if (!version) {
  throw new Error("Latest version not found.");
}

console.log(`Found version: ${formatVersion(version)}`);

// And download it.
const onProgress = (loaded: number, total: number) => {
  const progressPercent = Math.round((loaded / total) * 100)
    .toString()
    .padStart(3, " ");

  const numberLength = total.toString().length;
  const loadedBytesString = loaded.toString().padStart(numberLength, " ");

  process.stdout.clearLine(0);
  process.stdout.cursorTo(0);
  process.stdout.write(
    `\rLoaded ${loadedBytesString} of ${total}. ${progressPercent}%`
  );
};

await downloadVersion(version, downloadedFilePath, onProgress);
console.log("Download complete!");
