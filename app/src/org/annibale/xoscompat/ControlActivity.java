package org.annibale.xoscompat;
import android.app.Activity;
import android.content.*;
import android.os.Bundle;
import android.widget.Toast;
public final class ControlActivity extends Activity {
 static Intent receiveIntent(){return new Intent(Intent.ACTION_SEND).setType("*/*").setComponent(new ComponentName("com.miui.mishare.connectivity","com.xiaomi.sharop.AirDropShareTrampolineActivity")).putExtra("org.annibale.xoscompat.OPEN_RECEIVE",true).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);}
 @Override public void onCreate(Bundle saved){
  super.onCreate(saved);
  try{startActivity(receiveIntent());}catch(RuntimeException error){Toast.makeText(this,"无法打开接收页面，请确认已安装匹配版本的小米互传",Toast.LENGTH_LONG).show();}
  finish();
 }
}
