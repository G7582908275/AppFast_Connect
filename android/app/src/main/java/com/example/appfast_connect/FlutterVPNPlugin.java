package com.widewired.appfast_connect;

import android.app.Activity;
import android.content.Intent;
import android.net.VpnService;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import java.util.HashMap;
import java.util.Map;

public class FlutterVPNPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private static final String METHOD_CHANNEL = "appfast_connect/vpn";
    private static final String EVENT_CHANNEL = "appfast_connect/vpn_events";
    private static final int VPN_REQUEST_CODE = 1001;
    
    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private EventChannel.EventSink eventSink;
    private Activity activity;
    private Result pendingResult;
    private Handler mainHandler;
    
    // VPN状态
    private boolean isVPNRunning = false;
    private long uploadBytes = 0;
    private long downloadBytes = 0;
    
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL);
        methodChannel.setMethodCallHandler(this);
        
        eventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }
            
            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });
        
        mainHandler = new Handler(Looper.getMainLooper());
    }
    
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "startVPN":
                startVPN(call, result);
                break;
            case "stopVPN":
                stopVPN(result);
                break;
            case "getVPNStatus":
                getVPNStatus(result);
                break;
            case "requestVPNPermission":
                requestVPNPermission(result);
                break;
            case "checkVPNPermission":
                checkVPNPermission(result);
                break;
            case "getConnectionStats":
                getConnectionStats(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }
    
    private void startVPN(MethodCall call, Result result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null);
            return;
        }
        
        // 检查VPN权限
        Intent intent = VpnService.prepare(activity);
        if (intent != null) {
            pendingResult = result;
            activity.startActivityForResult(intent, VPN_REQUEST_CODE);
        } else {
            // 权限已授予，直接启动VPN服务
            startVPNService(call, result);
        }
    }
    
    private void startVPNService(MethodCall call, Result result) {
        try {
            // 获取参数
            String subscriptionId = call.argument("subscriptionId");
            String serverAddress = call.argument("serverAddress");
            Integer serverPort = call.argument("serverPort");
            String encryptionMethod = call.argument("encryptionMethod");
            String password = call.argument("password");
            
            // 启动VPN服务
            Intent serviceIntent = new Intent(activity, AppFastVPNService.class);
            serviceIntent.setAction("START_VPN");
            serviceIntent.putExtra("subscriptionId", subscriptionId);
            serviceIntent.putExtra("serverAddress", serverAddress);
            serviceIntent.putExtra("serverPort", serverPort != null ? serverPort : 443);
            serviceIntent.putExtra("encryptionMethod", encryptionMethod);
            serviceIntent.putExtra("password", password);
            
            activity.startService(serviceIntent);
            
            isVPNRunning = true;
            result.success(true);
            
            // 发送状态更新事件
            sendVPNStatusUpdate();
            
        } catch (Exception e) {
            result.error("VPN_START_ERROR", "启动VPN服务失败: " + e.getMessage(), null);
        }
    }
    
    private void stopVPN(Result result) {
        try {
            if (activity != null) {
                Intent serviceIntent = new Intent(activity, AppFastVPNService.class);
                serviceIntent.setAction("STOP_VPN");
                activity.startService(serviceIntent);
            }
            
            isVPNRunning = false;
            result.success(true);
            
            // 发送状态更新事件
            sendVPNStatusUpdate();
            
        } catch (Exception e) {
            result.error("VPN_STOP_ERROR", "停止VPN服务失败: " + e.getMessage(), null);
        }
    }
    
    private void getVPNStatus(Result result) {
        Map<String, Object> status = new HashMap<>();
        status.put("isConnected", isVPNRunning);
        status.put("uploadBytes", uploadBytes);
        status.put("downloadBytes", downloadBytes);
        result.success(status);
    }
    
    private void requestVPNPermission(Result result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null);
            return;
        }
        
        Intent intent = VpnService.prepare(activity);
        if (intent != null) {
            pendingResult = result;
            activity.startActivityForResult(intent, VPN_REQUEST_CODE);
        } else {
            result.success(true);
        }
    }
    
    private void checkVPNPermission(Result result) {
        if (activity == null) {
            result.success(false);
            return;
        }
        
        Intent intent = VpnService.prepare(activity);
        result.success(intent == null); // 如果intent为null，说明权限已授予
    }
    
    private void getConnectionStats(Result result) {
        Map<String, Object> stats = new HashMap<>();
        stats.put("uploadBytes", uploadBytes);
        stats.put("downloadBytes", downloadBytes);
        stats.put("uploadSpeed", formatSpeed(uploadBytes));
        stats.put("downloadSpeed", formatSpeed(downloadBytes));
        result.success(stats);
    }
    
    private String formatSpeed(long bytes) {
        if (bytes < 1024) return bytes + " B/s";
        if (bytes < 1024 * 1024) return String.format("%.1f KB/s", bytes / 1024.0);
        if (bytes < 1024 * 1024 * 1024) return String.format("%.1f MB/s", bytes / (1024.0 * 1024.0));
        return String.format("%.1f GB/s", bytes / (1024.0 * 1024.0 * 1024.0));
    }
    
    private void sendVPNStatusUpdate() {
        if (eventSink != null) {
            mainHandler.post(() -> {
                Map<String, Object> status = new HashMap<>();
                status.put("isConnected", isVPNRunning);
                status.put("uploadBytes", uploadBytes);
                status.put("downloadBytes", downloadBytes);
                eventSink.success(status);
            });
        }
    }
    
    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == VPN_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                // VPN权限已授予
                if (pendingResult != null) {
                    pendingResult.success(true);
                    pendingResult = null;
                }
            } else {
                // VPN权限被拒绝
                if (pendingResult != null) {
                    pendingResult.error("VPN_PERMISSION_DENIED", "VPN权限被拒绝", null);
                    pendingResult = null;
                }
            }
            return true;
        }
        return false;
    }
    
    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
    }
    
    @Override
    public void onDetachedFromActivityForConfigChanges() {
        activity = null;
    }
    
    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
    }
    
    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }
    
    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
    }
}
