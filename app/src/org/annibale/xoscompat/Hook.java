package org.annibale.xoscompat;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.wifi.WifiManager;
import android.util.Log;
import de.robv.android.xposed.IXposedHookLoadPackage;
import de.robv.android.xposed.XC_MethodHook;
import de.robv.android.xposed.XposedBridge;
import de.robv.android.xposed.callbacks.XC_LoadPackage;
import java.lang.reflect.Method;
import java.util.HashSet;
import java.util.Set;

public final class Hook implements IXposedHookLoadPackage {
    private static final String PACKAGE = "com.miui.mishare.connectivity";
    private static final String TAG = "AnnibaleXosCompat";
    private static final String RADIO_PROPERTY = "sys.xos.exclusive";
    private final Set<Method> hookedReceivers = new HashSet<>();
    private Method getProperty;

    @Override
    public void handleLoadPackage(XC_LoadPackage.LoadPackageParam loaded) throws Throwable {
        if (!PACKAGE.equals(loaded.packageName)) {
            return;
        }

        Log.i(TAG, "HOOK_ACTIVE version=0.4.5");
        ReceiveShortcut.install();
        MdnsCompat.install();
        getProperty = Class.forName("android.os.SystemProperties")
                .getDeclaredMethod("get", String.class, String.class);
        reportWhileExclusive("getWifiState", WifiManager.WIFI_STATE_ENABLED);
        reportWhileExclusive("isWifiEnabled", true);
        XposedBridge.hookMethod(WifiManager.class.getDeclaredMethod("setWifiEnabled", boolean.class),
                new XC_MethodHook() {
                    @Override
                    protected void beforeHookedMethod(MethodHookParam param) {
                        if (Boolean.TRUE.equals(param.args[0]) && ownsRadio()) {
                            param.setResult(true);
                        }
                    }
                });

        XC_MethodHook register = new XC_MethodHook() {
            @Override
            protected void beforeHookedMethod(MethodHookParam param) {
                if (param.args[0] instanceof BroadcastReceiver
                        && param.args[1] instanceof IntentFilter
                        && ((IntentFilter) param.args[1]).hasAction(WifiManager.WIFI_STATE_CHANGED_ACTION)) {
                    watchReceiver((BroadcastReceiver) param.args[0]);
                }
            }
        };
        for (Method method : Class.forName("android.app.ContextImpl").getDeclaredMethods()) {
            Class<?>[] args = method.getParameterTypes();
            if (method.getName().startsWith("registerReceiver") && args.length >= 2
                    && args[0] == BroadcastReceiver.class && args[1] == IntentFilter.class) {
                XposedBridge.hookMethod(method, register);
            }
        }
    }

    private boolean ownsRadio() {
        try {
            return "1".equals(getProperty.invoke(null, RADIO_PROPERTY, ""));
        } catch (ReflectiveOperationException exception) {
            return false;
        }
    }

    private void reportWhileExclusive(String name, Object value) throws NoSuchMethodException {
        XposedBridge.hookMethod(WifiManager.class.getDeclaredMethod(name), new XC_MethodHook() {
            @Override
            protected void beforeHookedMethod(MethodHookParam param) {
                if (ownsRadio()) {
                    param.setResult(value);
                }
            }
        });
    }

    private synchronized void watchReceiver(BroadcastReceiver receiver) {
        try {
            Method method = receiver.getClass().getMethod("onReceive", Context.class, Intent.class);
            if (hookedReceivers.contains(method)) {
                return;
            }
            XposedBridge.hookMethod(method, new XC_MethodHook() {
                @Override
                protected void beforeHookedMethod(MethodHookParam param) {
                    Intent intent = (Intent) param.args[1];
                    if (intent != null && WifiManager.WIFI_STATE_CHANGED_ACTION.equals(intent.getAction())
                            && ownsRadio()) {
                        param.setResult(null);
                    }
                }
            });
            hookedReceivers.add(method);
        } catch (NoSuchMethodException | RuntimeException exception) {
            Log.w(TAG, "Could not hook a Wi-Fi receiver", exception);
        }
    }
}
