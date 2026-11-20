package org.annibale.xoscompat;
import android.app.PendingIntent;
import android.graphics.drawable.Icon;
import android.service.quicksettings.*;
public final class AirDropTile extends TileService {
 @Override public void onStartListening(){
  super.onStartListening();Tile tile=getQsTile();if(tile==null)return;
  tile.setLabel("接收 Apple 文件");tile.setSubtitle("打开接收页面");
  tile.setIcon(Icon.createWithResource(this,R.drawable.ic_airdrop));
  tile.setState(Tile.STATE_INACTIVE);tile.setStateDescription("打开与 Apple 设备互传的接收页面");tile.updateTile();
 }
 @Override public void onClick(){
  super.onClick();
  PendingIntent launch=PendingIntent.getActivity(this,0,ControlActivity.receiveIntent(),PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
  startActivityAndCollapse(launch);
 }
}
