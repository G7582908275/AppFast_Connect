package com.widewired.appfast_connect;

import android.content.Intent;
import android.net.VpnService;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.DatagramChannel;
import java.nio.channels.Selector;
import java.net.InetSocketAddress;

public class AppFastVPNService extends VpnService {
    private static final String TAG = "AppFastVPNService";
    private ParcelFileDescriptor vpnInterface = null;
    private boolean isRunning = false;
    private Thread vpnThread;
    
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "AppFast VPN服务启动");
        
        if (intent != null && "START_VPN".equals(intent.getAction())) {
            startVPN();
        } else if (intent != null && "STOP_VPN".equals(intent.getAction())) {
            stopVPN();
        }
        
        return START_STICKY;
    }
    
    private void startVPN() {
        try {
            // 配置VPN接口 - 参考sing-box的配置
            Builder builder = new Builder()
                .setSession("AppFast Connect")
                .addAddress("10.0.0.2", 32)  // 虚拟IP地址
                .addDnsServer("8.8.8.8")     // DNS服务器
                .addDnsServer("8.8.4.4")     // 备用DNS
                .addRoute("0.0.0.0", 0)     // 全局路由
                .setMtu(1500);              // MTU设置
            
            // 允许绕过VPN的应用（可选）
            // builder.addDisallowedApplication("com.example.app");
            
            vpnInterface = builder.establish();
            if (vpnInterface == null) {
                Log.e(TAG, "无法建立VPN接口");
                return;
            }
            
            isRunning = true;
            Log.d(TAG, "VPN接口建立成功，开始处理流量");
            
            // 启动VPN处理线程
            vpnThread = new Thread(this::processVPNTraffic);
            vpnThread.start();
            
        } catch (Exception e) {
            Log.e(TAG, "启动VPN失败", e);
        }
    }
    
    private void processVPNTraffic() {
        try {
            FileInputStream in = new FileInputStream(vpnInterface.getFileDescriptor());
            FileOutputStream out = new FileOutputStream(vpnInterface.getFileDescriptor());
            
            ByteBuffer packet = ByteBuffer.allocate(32767);
            
            while (isRunning) {
                // 读取VPN接口数据
                int length = in.read(packet.array());
                if (length > 0) {
                    packet.limit(length);
                    
                    // 解析IP包
                    byte[] data = packet.array();
                    if (data.length >= 20) { // 最小IP头长度
                        // 这里应该实现sing-box的代理逻辑
                        // 1. 解析IP包
                        // 2. 根据路由规则决定是否代理
                        // 3. 通过代理服务器转发
                        // 4. 接收代理服务器响应
                        
                        // 简化实现：直接转发（实际应该通过sing-box处理）
                        processPacket(data, length, out);
                    }
                    
                    packet.clear();
                }
            }
            
        } catch (IOException e) {
            Log.e(TAG, "VPN流量处理错误", e);
        }
    }
    
    private void processPacket(byte[] data, int length, FileOutputStream out) {
        try {
            // 这里应该实现完整的sing-box逻辑
            // 1. 解析IP头
            // 2. 检查目标地址
            // 3. 根据规则选择代理或直连
            // 4. 处理TCP/UDP流量
            
            // 简化实现：直接写回（实际应该通过代理）
            out.write(data, 0, length);
            
        } catch (IOException e) {
            Log.e(TAG, "处理数据包失败", e);
        }
    }
    
    private void stopVPN() {
        isRunning = false;
        
        if (vpnThread != null) {
            vpnThread.interrupt();
            vpnThread = null;
        }
        
        if (vpnInterface != null) {
            try {
                vpnInterface.close();
                vpnInterface = null;
            } catch (IOException e) {
                Log.e(TAG, "关闭VPN接口失败", e);
            }
        }
        
        Log.d(TAG, "VPN服务已停止");
        stopSelf();
    }
    
    @Override
    public void onDestroy() {
        stopVPN();
        super.onDestroy();
    }
}
