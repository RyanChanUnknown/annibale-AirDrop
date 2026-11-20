package org.annibale.xoscompat;
import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import de.robv.android.xposed.*;
final class ReceiveShortcut {
 static void install() throws NoSuchMethodException {
  XposedBridge.hookMethod(Activity.class.getDeclaredMethod("startActivity",Intent.class),new XC_MethodHook(){
   @Override protected void beforeHookedMethod(MethodHookParam p){
    Activity activity=(Activity)p.thisObject;
    if(!"com.xiaomi.sharop.AirDropShareTrampolineActivity".equals(activity.getClass().getName()))return;
    Intent source=activity.getIntent();
    if(source==null||!source.getBooleanExtra("org.annibale.xoscompat.OPEN_RECEIVE",false))return;
    Intent target=(Intent)p.args[0];
    if(target==null||!"com.miui.mishare.action.AIRDROP_SHARE_GATE".equals(target.getAction()))return;
    Intent receive=new Intent(target).setAction("com.miui.mishare.action.AIRDROP_SETTING_GATE");
    receive.removeExtra("com.miui.mishare.extra.AIRDROP_SHARE_EXTRAS");
    receive.removeExtra("com.miui.mishare.extra.AIRDROP_SOURCE_ACTION");
    p.args[0]=receive;Log.i("AnnibaleXosCompat","RECEIVE_SHORTCUT_ROUTE");
   }
  });
 }
}
