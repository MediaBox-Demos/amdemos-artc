import { common } from "@kit.AbilityKit";
import { resourceManager } from "@kit.LocalizationKit";
import { fileIo as fs } from '@kit.CoreFileKit';

/**
 * 沙箱文件管理器
 * 用于管理应用程序沙箱目录中的文件操作
 */
export class SandboxFileManager {
  private static instance: SandboxFileManager;
  private context: common.UIAbilityContext | null = null;
  private sandboxDirectoryPath: string = "";

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): SandboxFileManager {
    if (!SandboxFileManager.instance) {
      SandboxFileManager.instance = new SandboxFileManager();
    }
    return SandboxFileManager.instance;
  }

  /**
   * 初始化管理器（必须在其他方法调用前先调用）
   * @param context UIAbility上下文
   */
  public initialize(context: common.UIAbilityContext): void {
    this.context = context;
    this.sandboxDirectoryPath = context.filesDir;
    console.info(`SandboxFileManager initialized, path: ${this.sandboxDirectoryPath}`);
  }


  /**
   * 将rawfile中的文件拷贝到沙箱目录
   * @param sourceFileName rawfile中的文件名
   * @param destFileName 目标文件名（可选，默认使用源文件名）
   * @returns 拷贝后的完整路径
   */
  public copyRawFileToSandbox(sourceFileName: string, destFileName?: string): string {

    const targetFileName = destFileName || sourceFileName.split('/').pop()!;
    const destPath = `${this.sandboxDirectoryPath}/${targetFileName}`;

    try {
      // 获取源文件描述符
      const sourceFd = this.context!.resourceManager.getRawFdSync(sourceFileName);

      // 创建目标文件
      let destFd = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);

      // 缓冲区大小
      const bufferSize = 4096;
      const buffer = new ArrayBuffer(bufferSize);

      let offset = 0;
      let bytesRead = 0;
      let totalRead = 0;

      // 逐块拷贝文件
      while ((bytesRead = fs.readSync(sourceFd.fd, buffer, {
        offset: sourceFd.offset + offset,
        length: bufferSize
      })) > 0) {
        totalRead += bytesRead;
        fs.writeSync(destFd.fd, buffer, { offset: offset, length: bytesRead });
        offset += bytesRead;

        // 动态调整最后一块的大小
        if ((sourceFd.length - totalRead) < bufferSize) {
          // 最后一块，不需要重新分配buffer
        }
      }

      // 关闭文件描述符
      fs.closeSync(destFd);
      this.context!.resourceManager.closeRawFd(sourceFileName);

      console.info(`File copied successfully: ${sourceFileName} -> ${destPath}`);
      return destPath;

    } catch (error) {
      console.error(`Failed to copy file ${sourceFileName} to sandbox:`, error);
      return ''
    }
  }

  /**
   * 获取沙箱目录中的文件列表
   * @returns 文件名数组
   */
  public listFilesInSandbox(): string[] {
    try {
      return fs.listFileSync(this.sandboxDirectoryPath);
    } catch (error) {
      console.error('Failed to list files in sandbox:', error);
      return [];
    }
  }

  /**
   * 检查文件是否存在于沙箱中
   * @param fileName 文件名
   * @returns 是否存在
   */
  public fileExistsInSandbox(fileName: string): boolean {
    const filePath = `${this.sandboxDirectoryPath}/${fileName}`;
    try {
      fs.accessSync(filePath);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 获取沙箱中文件的完整路径
   * @param fileName 文件名
   * @returns 完整路径
   */
  public getSandboxFilePath(fileName: string): string {
    return `${this.sandboxDirectoryPath}/${fileName}`;
  }

  /**
   * 删除沙箱中的文件
   * @param fileName 文件名
   * @returns 是否删除成功
   */
  public deleteFileFromSandbox(fileName: string): boolean {
    const filePath = `${this.sandboxDirectoryPath}/${fileName}`;
    try {
      fs.unlinkSync(filePath);
      console.info(`File deleted: ${filePath}`);
      return true;
    } catch (error) {
      console.error(`Failed to delete file ${filePath}:`, error);
      return false;
    }
  }

  /**
   * 清理沙箱目录（删除所有文件）
   * @returns 删除的文件数量
   */
  public clearSandboxDirectory(): number {
    try {
      const files = this.listFilesInSandbox();
      let deletedCount = 0;

      for (const file of files) {
        if (this.deleteFileFromSandbox(file)) {
          deletedCount++;
        }
      }

      console.info(`Cleared sandbox directory, deleted ${deletedCount} files`);
      return deletedCount;
    } catch (error) {
      console.error('Failed to clear sandbox directory:', error);
      return 0;
    }
  }

  /**
   * 获取文件信息
   * @param fileName 文件名
   * @returns 文件信息或null
   */
  public getFileInfo(fileName: string): string | null {
    const filePath = `${this.sandboxDirectoryPath}/${fileName}`;
    try {
      return filePath;
    } catch (error) {
      console.error(`Failed to get file info for ${fileName}:`, error);
      return null;
    }
  }
}
