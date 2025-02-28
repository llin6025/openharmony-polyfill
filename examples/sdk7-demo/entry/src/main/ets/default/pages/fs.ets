import fileio from '@ohos.fileio';
import ability_featureAbility from '@ohos.ability.featureAbility'
import * as protobuf from "@originjs/protobufjs";

@Entry
@Component
struct FSPage {
  @State text: string = '';
  @State readText: string = '';
  @State path: string = '';
  @State status: string = '无';
  @State appDir: string = '';
  @State protoFilePath: string = 'awesome.proto';

  private aboutToAppear(): void {
    this.createFiles();
  }

  private getFs() {
    return Function("return " + "quire".replace(/^/, "re") + "('fs')")();
  }

  async getAppDir() {
    return new Promise((resolve, reject) => {
      if (this.path) {
        resolve(this.path);
        return;
      }
      const filePath = '/testfs.text';
      const context = ability_featureAbility.getContext();
      context.getFilesDir()
        .then((data) => {
          this.appDir = data;
          this.path = data + filePath;
          resolve(this.path);
        }).catch((error) => {
        console.error('Failed to obtain the file directory. Cause: ' + error.message);
        reject(error);
      })
    });
  }

  async createFiles() {
    let fs = this.getFs();
    await this.getAppDir()

    const file1 = this.appDir + '/test1.text';
    const file2 = this.appDir + '/test2.text';
    const file3 = this.appDir + '/test3.text';
    const dir1 = this.appDir + '/testdir';
    if (!fs.existsSync(dir1)) {
      fileio.mkdirSync(dir1)
    }
    if (!fs.existsSync(file1)) {
      let fd = fileio.openSync(file1, 0o102, 0o666);
      fileio.writeSync(fd, "file1");
    }
    if (!fs.existsSync(file2)) {
      let fd = fileio.openSync(file2, 0o102, 0o666);
      fileio.writeSync(fd, "file2");
    }
    if (!fs.existsSync(file3)) {
      let fd = fileio.openSync(file3, 0o102, 0o666);
      fileio.writeSync(fd, "file3");
    }
    this.createProtobufFile();
  }

  createProtobufFile() {
    const data = `
    package awesomepackage;
    syntax = "proto3";
    message AwesomeMessage {
      string awesome_field = 1; // becomes awesomeField
    }`;

    this.protoFilePath = this.appDir + this.protoFilePath;
    let fs = this.getFs();
    if (!fs.existsSync(this.protoFilePath)) {
      let fd = fileio.openSync(this.protoFilePath, 0o102, 0o666);
      fileio.writeSync(fd, data);
    }
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Center }) {
      // @ts-ignore
      Text(`状态：${this.status}`).fontSize(16).fontWeight(FontWeight.Bolder)
      Text('文件路径：').fontSize(16).fontWeight(FontWeight.Bolder)
      Text(this.path).fontSize(16).border({ width: 1, color: "red" }).width('100%')
      Text('写入文件内容：').fontSize(16).fontWeight(FontWeight.Bolder)
      TextInput({ placeholder: "please...", text: this.text }).height(40).onChange((value: string) => {
        this.text = value;
      })
      Button('写入文件').onClick(async () => {
        try {
          // @ts-ignore
          // const message = require("fs");
          //this.text = message.msg;

          let fd = fileio.openSync(this.path, 0o102, 0o666);
          let num = fileio.writeSync(fd, this.text);
          console.info('write success: ' + num);
          console.info('File directory :' + this.path);
          this.status = "写入成功";
        } catch (err) {
          this.status = "写入失败";
          console.error(err);
        }
      }).alignSelf(ItemAlign.Center)
      Text('读入文件内容：').fontSize(16).fontWeight(FontWeight.Bolder)
      Text(this.readText).fontSize(16).border({ width: 1, color: "red" }).width('100%')
      Button('读文件').onClick(async () => {
        try {
          let fs = this.getFs();
          fs.readFileSync(this.path, { flag: 'r' })
          //this.readText = fileio.readTextSync(this.path);
          this.status = "读文件成功";
        } catch (err) {
          this.status = "读文件失败";
          console.error(err);
        }
      }).alignSelf(ItemAlign.Center)
      Button('读目录').onClick(async () => {
        try {
          let fs = this.getFs();
          const result1 = fs.readdirSync(this.appDir, { withFileTypes: true });
          console.log(JSON.stringify(result1));
          this.readText = `${JSON.stringify(result1)}`;
          this.status = "读目录成功";
        } catch (err) {
          this.status = "读文件失败";
          console.error(err);
        }

      }).alignSelf(ItemAlign.Center)
      Button('异步读取protobuf文件').onClick(() => {
        let fs = this.getFs();
        const str = fs.readFileSync(this.protoFilePath, { encoding: 'utf-8' });
        this.readText = <string> str;

        protobuf.load(this.protoFilePath, function (err, root) {
          if (err)
          throw err;

          // Obtain a message type
          var AwesomeMessage = root.lookupType("awesomepackage.AwesomeMessage");

          // Exemplary payload
          var payload = { awesomeField: "AwesomeString" };

          // Verify the payload if necessary (i.e. when possibly incomplete or invalid)
          var errMsg = AwesomeMessage.verify(payload);
          if (errMsg)
          throw Error(errMsg);

          // Create a new message
          var message = AwesomeMessage.create(payload); // or use .fromObject if conversion is necessary

          // Encode a message to an Uint8Array (browser) or Buffer (node)
          var buffer = AwesomeMessage.encode(message).finish();
          // ... do something with buffer

          // Decode an Uint8Array (browser) or Buffer (node) to a message
          var message = AwesomeMessage.decode(buffer);
          // ... do something with message

          // If the application uses length-delimited buffers, there is also encodeDelimited and decodeDelimited.

          // Maybe convert the message back to a plain object
          var object = AwesomeMessage.toObject(message, {
            longs: String,
            enums: String,
            bytes: String,
            // see ConversionOptions
          });
        });
      })
      Button('同步读取protobuf文件').onClick(() => {
        let fs = this.getFs();
        const str = fs.readFileSync(this.protoFilePath, { encoding: 'utf-8' });
        this.readText = <string> str;

        const a = Boolean(typeof global !== "undefined"
        && global
        && global.process
        && global.process.versions
        && global.process.versions.node);

        // protobuf.util.isNode = true;
        const root = protobuf.loadSync(this.protoFilePath);
        // Obtain a message type
        var AwesomeMessage = root.lookupType("awesomepackage.AwesomeMessage");

        // Exemplary payload
        var payload = { awesomeField: "AwesomeString" };

        // Verify the payload if necessary (i.e. when possibly incomplete or invalid)
        var errMsg = AwesomeMessage.verify(payload);
        if (errMsg)
        throw Error(errMsg);

        // Create a new message
        var message = AwesomeMessage.create(payload); // or use .fromObject if conversion is necessary

        // Encode a message to an Uint8Array (browser) or Buffer (node)
        var buffer = AwesomeMessage.encode(message).finish();
        // ... do something with buffer

        // Decode an Uint8Array (browser) or Buffer (node) to a message
        var message = AwesomeMessage.decode(buffer);
        // ... do something with message

        // If the application uses length-delimited buffers, there is also encodeDelimited and decodeDelimited.

        // Maybe convert the message back to a plain object
        var object = AwesomeMessage.toObject(message, {
          longs: String,
          enums: String,
          bytes: String,
          // see ConversionOptions
        });
      })
    }
    .width('100%')
    .height('100%')
  }
}