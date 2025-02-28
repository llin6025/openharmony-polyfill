import fileio from '@ohos.fileio';

const FILE_TYPE = { File: 1, Dirent: 2 };
//type BufferEncoding = 'ascii' | 'utf8' | 'utf-8' | 'utf16le' | 'ucs2' | 'ucs-2' | 'base64' | 'base64url' | 'latin1' | 'binary' | 'hex';
// 1.File 2.Dirent
const fileType = Symbol('type');

/**
 * Reads the contents of the directory.
 * @param {string} path - directory path
 * @param {string | Object } [options = { encoding : 'utf-8', withFileTypes: false}] - The optional options argument can
 * be a string specifying an encoding, or an object with an encoding property specifying the character encoding to use
 * for the filenames returned.
 * @returns {string[] | fileio.Dirent[]}
 */
function readdirSync(path, options) {
  const dirStream = fileio.opendirSync(path);
  let dirent;
  const result = [];

  if (!options) {
    options = { encoding: 'utf-8', withFileTypes: false };
  }

  // eslint-disable-next-line
  while (true) {
    dirent = dirStream.readSync();
    if (!dirent) {
      dirStream.closeSync();
      break;
    }

    if (options.withFileTypes) {
      Object.defineProperty(dirent, fileType, {
        value: dirent.isDirectory() ? FILE_TYPE.Dirent : FILE_TYPE.File,
        enumerable: true
      });

      dirent.toJSON = function () {
        return { name: this.name };
      };
      result.push(dirent);
    } else {
      result.push(dirent.name);
    }
  }
  return result;
}

/**
 * readFileSync
 * @param path
 * @param options
 * @returns {string | Buffer}
 */
function readFileSync(path, options) {
  if (!options) {
    options = {};
  }
  let Buffer = require('buffer').Buffer;
  const mode = options.flag || 'r';
  let stream = fileio.createStreamSync(path, mode);

  let data = [];
  let count = 0;
  // eslint-disable-next-line
  while (true) {
    let buffer = new ArrayBuffer(4096);
    let num = stream.readSync(buffer);
    if (0 == num) {
      break;
    }
    if (num < 4096) {
      data.push(buffer.slice(0, num));
    } else {
      data.push(buffer);
    }
    count += num;
  }
  stream.closeSync();
  //const buffer = new Buffer(count);
  const buffer = Buffer.alloc(count);
  let offset = 0;

  for (let arr of data) {
    let uint8Arr = new Uint8Array(arr);
    buffer.set(uint8Arr, offset);
    offset += arr.byteLength;
  }

  if (options.encoding) {
    return buffer.toString(options.encoding);
  }
  return buffer;
}

/**
 * Returns true if the path exists, false otherwise.
 * @param {string} path
 * @returns {boolean}
 */
function existsSync(path) {
  try {
    fileio.accessSync(path);
    return true;
  } catch (e) {
    if (e.message == 'No such file or directory') {
      return false;
    }
    throw e;
  }
}

function writeFileSync() {}

function unlinkSync() {}

function createWriteStream() {}

/**
 * readFile callback
 *
 * @callback readFileCallback
 * @param {Error} err
 * @param {string  | Buffer} data
 */

/**
 * readFile
 * @param {string} path
 * @param {string | Object } [options = { encoding : null, flag: 'r',signal: AbortSignal}]  [options]
 * @param {readFileCallback } callback
 */
function readFile(path, options, callback) {
  if (typeof options == 'function') {
    callback = options;
  }

  if (!options) {
    options = {};
  }

  if (typeof callback == 'function') {
    readFilePromises(path, options)
      .then((data) => callback(null, data))
      .catch((err) => callback(err, null));
  } else {
    return readFilePromises(path, options);
  }
}

function readFilePromises(path, options) {
  if (!options) {
    options = {};
  }

  function _readFile(resolve, reject) {
    let Buffer = require('buffer').Buffer;
    const mode = options.flag || 'r';

    fileio.createStream(path, mode, async function (err, stream) {
      if (err) {
        reject(err);
        return;
      }

      let data = [];
      let count = 0;
      let readOut;
      try {
        // eslint-disable-next-line
        while (true) {
          readOut = await stream.read(new ArrayBuffer(4096));
          if (0 == readOut.bytesRead) {
            break;
          }
          if (readOut.bytesRead < 4096) {
            data.push(readOut.buffer.slice(0, readOut.bytesRead));
          } else {
            data.push(readOut.buffer);
          }
          count += readOut.bytesRead;
        }
      } catch (error) {
        reject(error);
        return;
      }

      stream.closeSync();
      // const buffer = new Buffer(count);
      const buffer = Buffer.alloc(count);
      let offset = 0;

      for (let arr of data) {
        let uint8Arr = new Uint8Array(arr);
        buffer.set(uint8Arr, offset);
        offset += arr.byteLength;
      }

      if (options.encoding) {
        resolve(buffer.toString(options.encoding));
      } else {
        resolve(buffer);
      }
    });
  }

  const Promises = require('promise');
  return new Promises(_readFile);
}

const harmonyFS = {
  readdirSync,
  readFileSync,
  existsSync,
  writeFileSync,
  unlinkSync,
  createWriteStream,
  readFile
};

export default harmonyFS;
