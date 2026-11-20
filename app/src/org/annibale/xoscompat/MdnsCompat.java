package org.annibale.xoscompat;
import android.util.Log;
import de.robv.android.xposed.*;
import java.io.IOException;
import java.net.*;
final class MdnsCompat {
 static void install() throws NoSuchMethodException {
  XposedBridge.hookMethod(MulticastSocket.class.getDeclaredMethod("joinGroup",SocketAddress.class,NetworkInterface.class),new XC_MethodHook(){
   @Override protected void afterHookedMethod(MethodHookParam p){
    if(!(p.args[0] instanceof InetSocketAddress)||!(p.args[1] instanceof NetworkInterface))return;
    InetSocketAddress group=(InetSocketAddress)p.args[0];NetworkInterface nic=(NetworkInterface)p.args[1];
    MulticastSocket socket=(MulticastSocket)p.thisObject;
    if(group.getPort()!=5353||socket.getLocalPort()!=5353||!"xos0".equals(nic.getName()))return;
    try{
     if(!InetAddress.getByName("ff02::fb").equals(group.getAddress()))return;
     socket.setNetworkInterface(nic);socket.setTimeToLive(255);
     Log.i("AnnibaleXosCompat","MDNS_XOS_OUTBOUND_INTERFACE_FIXED hop=255");
    }catch(IOException error){Log.w("AnnibaleXosCompat","MDNS_XOS_BIND_FAILED",error);}
   }
  });
 }
}
