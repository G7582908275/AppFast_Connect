import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger.dart';

// 定义密码输入回调类型
typedef PasswordInputCallback = Future<String?> Function(String message);

class PermissionUtils {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _sudoPasswordKey = 'sudo_password';
  
  // 密码输入回调函数
  static PasswordInputCallback? _passwordInputCallback;
  
  /// 设置密码输入回调函数
  static void setPasswordInputCallback(PasswordInputCallback callback) {
    _passwordInputCallback = callback;
  }
  
  /// 检查应用是否以管理员权限运行
  static Future<bool> isRunningAsAdmin() async {
    if (Platform.isMacOS) {
      try {
        // 尝试执行需要管理员权限的命令
        final result = await Process.run('sudo', ['-n', 'true']);
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    } else if (Platform.isWindows) {
      // Windows: 无需检查管理员权限，直接返回true
      return true;
    } else if (Platform.isLinux) {
      try {
        // Linux: 检查是否以root身份运行
        final result = await Process.run('id', ['-u']);
        if (result.exitCode == 0) {
          final uid = result.stdout.toString().trim();
          return uid == '0'; // root用户的UID是0
        }
        return false;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  
  /// 检查是否有网络扩展权限
  static Future<bool> hasNetworkExtensionPermission() async {
    if (Platform.isMacOS) {
      try {
        // 检查是否有网络扩展权限 - 尝试访问网络接口
        final result = await Process.run('ifconfig', ['lo0']);
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    } else if (Platform.isWindows) {
      try {
        // Windows: 检查网络接口访问权限
        final result = await Process.run('netsh', ['interface', 'show', 'interface']);
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    } else if (Platform.isLinux) {
      try {
        // Linux: 检查网络接口访问权限
        final result = await Process.run('ip', ['link', 'show']);
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  
  /// 检查 sudo 权限（用于 VPN 操作）
  static Future<bool> hasSudoPrivileges() async {
    if (Platform.isMacOS) {
      try {
        // 尝试执行 sudo 命令，检查是否有权限
        final result = await Process.run('sudo', ['-n', 'true']);
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    } else if (Platform.isWindows) {
      // Windows: 无需检查管理员权限，直接返回true
      return true;
    } else if (Platform.isLinux) {
      // Linux: 检查是否有root权限或sudo权限
      try {
        final result = await Process.run('sudo', ['-n', 'true']);
        return result.exitCode == 0;
      } catch (e) {
        return await isRunningAsAdmin();
      }
    }
    return false;
  }
  
  /// 从安全存储中读取保存的密码
  static Future<String?> _getSavedPassword() async {
    try {
      return await _storage.read(key: _sudoPasswordKey);
    } catch (e) {
      return null;
    }
  }
  
  /// 将密码保存到安全存储中
  static Future<void> _savePassword(String password) async {
    try {
      await _storage.write(key: _sudoPasswordKey, value: password);
    } catch (e) {
      // 忽略保存错误
    }
  }
  
  /// 清除保存的密码
  static Future<void> _clearSavedPassword() async {
    try {
      await _storage.delete(key: _sudoPasswordKey);
    } catch (e) {
      // 忽略删除错误
    }
  }
  
  /// 公开方法：手动清除保存的密码
  static Future<bool> clearSavedPassword() async {
    if (Platform.isMacOS) {
      try {
        await _storage.delete(key: _sudoPasswordKey);
        return true;
      } catch (e) {
        return false;
      }
    } else if (Platform.isWindows || Platform.isLinux) {
      // Windows和Linux平台也支持清除密码（如果将来需要）
      try {
        await _storage.delete(key: _sudoPasswordKey);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  
  /// 检查是否有保存的密码
  static Future<bool> hasSavedPassword() async {
    if (Platform.isMacOS) {
      try {
        final password = await _storage.read(key: _sudoPasswordKey);
        return password != null && password.isNotEmpty;
      } catch (e) {
        return false;
      }
    } else if (Platform.isWindows || Platform.isLinux) {
      // Windows和Linux平台也支持检查密码（如果将来需要）
      try {
        final password = await _storage.read(key: _sudoPasswordKey);
        return password != null && password.isNotEmpty;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  
  /// 验证密码是否正确
  static Future<bool> _validatePassword(String password) async {
    try {
      final process = await Process.start('sudo', ['-S', 'true']);
      process.stdin.write(password);
      await process.stdin.close();
      final result = await process.exitCode;
      return result == 0;
    } catch (e) {
      return false;
    }
  }
  
    /// 请求 sudo 权限（使用Flutter对话框）
  static Future<bool> requestSudoPrivileges() async {
    if (Platform.isMacOS) {
      try {
        await Logger.logInfo('开始请求sudo权限...');
        
        // 首先尝试使用保存的密码
        final savedPassword = await _getSavedPassword();
        if (savedPassword != null && savedPassword.isNotEmpty) {
          await Logger.logInfo('尝试使用保存的密码...');
          final isValid = await _validatePassword(savedPassword);
          if (isValid) {
            await Logger.logInfo('保存的密码有效');
            // 密码有效，更新 sudo 缓存
            final cacheProcess = await Process.start('sudo', ['-S', 'true']);
            cacheProcess.stdin.write(savedPassword);
            await cacheProcess.stdin.close();
            await cacheProcess.exitCode;
            return true;
          } else {
            await Logger.logWarning('保存的密码无效，清除它');
            // 保存的密码无效，清除它
            await _clearSavedPassword();
          }
        }
        
        // 如果没有保存的密码或密码无效，请求用户输入
        await Logger.logInfo('请求用户输入密码...');
        
        if (_passwordInputCallback == null) {
          await Logger.logError('密码输入回调未设置');
          return false;
        }
        
        final password = await _passwordInputCallback!('连接网络需要管理员权限，请输入密码:');
        if (password == null || password.isEmpty) {
          await Logger.logWarning('用户没有输入密码或取消了输入');
          return false;
        }
        
        // 验证密码是否正确
        await Logger.logInfo('验证密码...');
        final isValid = await _validatePassword(password);
        if (isValid) {
          await Logger.logInfo('密码验证成功，保存到安全存储');
          // 密码正确，保存到安全存储
          await _savePassword(password);
          
          // 更新 sudo 缓存
          final cacheProcess = await Process.start('sudo', ['-S', 'true']);
          cacheProcess.stdin.write(password);
          await cacheProcess.stdin.close();
          await cacheProcess.exitCode;
          
          return true;
        } else {
          await Logger.logError('密码验证失败');
          return false;
        }
      } catch (e) {
        await Logger.logError('请求sudo权限时发生错误', e);
        return false;
      }
    } else if (Platform.isWindows) {
      // Windows: 无需检查管理员权限，直接返回true
      try {
        await Logger.logInfo('Windows平台：无需管理员权限检查');
        return true;
      } catch (e) {
        await Logger.logError('Windows权限检查时发生错误', e);
        return false;
      }
    } else if (Platform.isLinux) {
      // Linux: 提示用户使用sudo运行
      await Logger.logInfo('Linux平台：需要sudo权限');
      if (_passwordInputCallback != null) {
        await _passwordInputCallback!('Linux平台需要sudo权限。请使用sudo运行应用或确保有适当的权限。');
      }
      return false;
    }
    return false;
  }

  /// 请求 sudo 权限并执行特定命令
  static Future<bool> requestSudoAndExecute(List<String> command, {String? workingDirectory}) async {
    if (Platform.isMacOS) {
      try {
        if (_passwordInputCallback == null) {
          await Logger.logError('密码输入回调未设置');
          return false;
        }
        
        final password = await _passwordInputCallback!('网络连接需要管理员权限，请输入密码:');
        if (password == null || password.isEmpty) {
          await Logger.logWarning('用户没有输入密码或取消了输入');
          return false;
        }
        
        // 构建完整的 sudo 命令
        final sudoCommand = ['sudo', '-S', ...command];
        
        // 执行命令
        final process = await Process.start(sudoCommand[0], sudoCommand.skip(1).toList());
        process.stdin.write(password);
        await process.stdin.close();
        final result = await process.exitCode;
        
        return result == 0;
      } catch (e) {
        await Logger.logError('执行sudo命令时发生错误', e);
        return false;
      }
    } else if (Platform.isWindows) {
      // Windows: 直接执行命令（假设已有管理员权限）
      try {
        final process = await Process.start(command[0], command.skip(1).toList());
        final result = await process.exitCode;
        return result == 0;
      } catch (e) {
        await Logger.logError('执行Windows命令时发生错误', e);
        return false;
      }
    } else if (Platform.isLinux) {
      // Linux: 尝试使用sudo执行命令
      try {
        final sudoCommand = ['sudo', ...command];
        final process = await Process.start(sudoCommand[0], sudoCommand.skip(1).toList());
        final result = await process.exitCode;
        return result == 0;
      } catch (e) {
        await Logger.logError('执行Linux命令时发生错误', e);
        return false;
      }
    }
    return false;
  }
  
  /// 检查并确保有必要的权限（启动时检查）
  static Future<bool> ensureRequiredPermissions() async {
    if (Platform.isMacOS) {
      // 在启动时不强制要求管理员权限，让应用正常启动
      return true;
    } else if (Platform.isWindows) {
        // Windows: 无需检查管理员权限，直接返回true
      return true;
    } else if (Platform.isLinux) {
      // Linux: 检查是否有root权限或sudo权限
      final hasPrivileges = await hasSudoPrivileges();
      if (!hasPrivileges) {
        await Logger.logWarning('Linux应用没有足够的权限，功能可能受限');
      }
      return true; // 允许应用启动，但会记录警告
    }
    return true;
  }
}
