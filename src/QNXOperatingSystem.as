package
{
//Imports
import qnx.system.QNXApplication;
import qnx.events.QNXApplicationEvent;

//Class
public final class QNXOperatingSystem
	{
	//Constructor
	public function QNXOperatingSystem()
		{
		QNXApplication.qnxApplication.addEventListener(QNXApplicationEvent.SWIPE_DOWN, swipeDownEventHandler);
		}
		
	//Swipe Down Event Handler
	private function swipeDownEventHandler(evt:QNXApplicationEvent):void
		{
		DropSwatch.controller.preferencesPanel.show();
		}
	}
}