import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PermissionUtils {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _sudoPasswordKey = 'sudo_password';
  
  /// 检查应用是否以管理员权限运行
  /// 检查应用是否以管理员权限运行
  static Future<bool> isRunningAsAdmin() async {
    if (!Platform.isMacOS) return false;
    
    try {
      // 尝试执行需要管理员权限的命令
      final result = await Process.run('sudo', ['-n', 'true']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// 检查是否有网络扩展权限
  static Future<bool> hasNetworkExtensionPermission() async {
    if (!Platform.isMacOS) return false;
    
    try {
      // 检查是否有网络扩展权限 - 尝试访问网络接口
      final result = await Process.run('ifconfig', ['lo0']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// 请求管理员权限（通过重新启动应用）
  static Future<bool> requestAdminPrivileges() async {
    if (!Platform.isMacOS) return false;
    
    try {
      // 获取当前应用的路径
      final appPath = Platform.resolvedExecutable;
      final appDir = Directory(appPath).parent.parent.parent.parent.parent;
      
      // 使用 osascript 请求管理员权限重新启动应用
      final script = '''
        tell application "System Events"
          set appPath to "$appDir"
          do shell script "open -a \\"" & appPath & "\\"" with administrator privileges"
        end tell
      ''';
      
      final result = await Process.run('osascript', ['-e', script]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// 请求网络扩展权限
  static Future<bool> requestNetworkExtensionPermission() async {
    if (!Platform.isMacOS) return false;
    
    try {
      // 显示权限请求对话框 - 简化版本
      final script = '''
        tell application "System Preferences"
          activate
          set current pane to pane id "com.apple.preference.security"
        end tell
      ''';
      
      final result = await Process.run('osascript', ['-e', script]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// 主动请求管理员权限并重新启动应用
  static Future<void> requestAdminAndRestart() async {
    if (!Platform.isMacOS) return;
    
    try {
      // 获取当前应用的路径
      final appPath = Platform.resolvedExecutable;
      final appDir = Directory(appPath).parent.parent.parent.parent.parent;
      
      // 首先显示一个对话框通知用户
      final dialogScript = '''
        tell application "System Events"
          display dialog "此应用需要管理员权限才能正常运行。\\n\\n请点击确定，系统将弹出密码框请求管理员权限。" buttons {"确定", "取消"} default button "确定" with icon note
        end tell
      ''';
      
      final dialogResult = await Process.run('osascript', ['-e', dialogScript]);
      if (dialogResult.exitCode != 0) {
        return;
      }
      
      // 使用 osascript 请求管理员权限重新启动应用
      final script = '''
        tell application "System Events"
          set appPath to "$appDir"
          do shell script "open -a \\"" & appPath & "\\"" with administrator privileges"
        end tell
      ''';
      
      final result = await Process.run('osascript', ['-e', script]);
      if (result.exitCode == 0) {
        // 等待一段时间让新进程启动
        await Future.delayed(const Duration(seconds: 2));
        // 退出当前进程
        exit(0);
      }
    } catch (e) {
      // Failed to request admin privileges
    }
  }
  
  /// 检查并确保有必要的权限（启动时检查）
  static Future<bool> ensureRequiredPermissions() async {
    if (!Platform.isMacOS) return true;
    
    // 在启动时不强制要求管理员权限，让应用正常启动
    // 权限检查将在 VPN 连接时进行
    return true;
  }
  
  /// 检查 sudo 权限（用于 VPN 操作）
  static Future<bool> hasSudoPrivileges() async {
    if (!Platform.isMacOS) return false;
    
    try {
      // 尝试执行 sudo 命令，检查是否有权限
      final result = await Process.run('sudo', ['-n', 'true']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
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
    if (!Platform.isMacOS) return false;
    
    try {
      await _storage.delete(key: _sudoPasswordKey);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 检查是否有保存的密码
  static Future<bool> hasSavedPassword() async {
    if (!Platform.isMacOS) return false;
    
    try {
      final password = await _storage.read(key: _sudoPasswordKey);
      return password != null && password.isNotEmpty;
    } catch (e) {
      return false;
    }
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
  
  /// 请求 sudo 权限（会弹出密码框）
  static Future<bool> requestSudoPrivileges() async {
    if (!Platform.isMacOS) return false;
    
    try {
      // 首先尝试使用保存的密码
      final savedPassword = await _getSavedPassword();
      if (savedPassword != null && savedPassword.isNotEmpty) {
        final isValid = await _validatePassword(savedPassword);
        if (isValid) {
          // 密码有效，更新 sudo 缓存
          final cacheProcess = await Process.start('sudo', ['-S', 'true']);
          cacheProcess.stdin.write(savedPassword);
          await cacheProcess.stdin.close();
          await cacheProcess.exitCode;
          return true;
        } else {
          // 保存的密码无效，清除它
          await _clearSavedPassword();
        }
      }
      
      // 如果没有保存的密码或密码无效，请求用户输入
      final passwordScript = '''
        tell application "System Events"
          set passwordResult to display dialog "VPN 连接需要管理员权限，请输入管理员密码:" default answer "" with hidden answer buttons {"确定", "取消"} default button "确定" with icon caution
          set userPassword to text returned of passwordResult
          return userPassword
        end tell
      ''';
      
      final passwordResult = await Process.run('osascript', ['-e', passwordScript]);
      if (passwordResult.exitCode != 0) {
        return false;
      }
      
      final password = passwordResult.stdout.toString().trim();
      if (password.isEmpty) {
        return false;
      }
      
      // 验证密码是否正确
      final isValid = await _validatePassword(password);
      if (isValid) {
        // 密码正确，保存到安全存储
        await _savePassword(password);
        
        // 更新 sudo 缓存
        final cacheProcess = await Process.start('sudo', ['-S', 'true']);
        cacheProcess.stdin.write(password);
        await cacheProcess.stdin.close();
        await cacheProcess.exitCode;
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 请求 sudo 权限并执行特定命令
  static Future<bool> requestSudoAndExecute(List<String> command, {String? workingDirectory}) async {
    if (!Platform.isMacOS) return false;
    
    try {
      // 使用 osascript 创建一个密码输入对话框
      final passwordScript = '''
        tell application "System Events"
          set passwordResult to display dialog "VPN 连接需要管理员权限，请输入管理员密码:" default answer "" with hidden answer buttons {"确定", "取消"} default button "确定" with icon caution
          set userPassword to text returned of passwordResult
          return userPassword
        end tell
      ''';
      
      final passwordResult = await Process.run('osascript', ['-e', passwordScript]);
      if (passwordResult.exitCode != 0) {
        return false;
      }
      
      final password = passwordResult.stdout.toString().trim();
      if (password.isEmpty) {
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
      return false;
    }
  }
}
