package
{
//Imports
import com.mattie.data.Preferences;
import flash.desktop.NativeApplication;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.GradientType;
import flash.display.NativeWindow;
import flash.display.NativeWindowInitOptions;
import flash.display.PixelSnapping;
import flash.display.Shape;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.NativeWindowBoundsEvent;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import flash.system.Capabilities;
import flash.text.AntiAliasType;
import flash.text.Font;
import flash.text.StyleSheet;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;

//Class
public final class HelpWindow extends NativeWindow
	{
	//Constants
	public static const PREFS_HELP_WINDOW_BOUNDS:String = "prefsHelpWindowBounds";
	
	//Properties
	public static var windowBounds:Rectangle;
	
	private static var singleton:HelpWindow;
	
	//Variables	
	private var helpWindow:NativeWindow;
	private var backgroundGradient:Shape;
	private var helpIcon:Bitmap;
	private var helpTitleTextField:TextField;
	private var helpBodyTextField:TextField;

	//Constructor
	public function HelpWindow()
		{
		var windowInitOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
		windowInitOptions.maximizable = false;
		windowInitOptions.minimizable = false;
		windowInitOptions.resizable = false;
		
		super(windowInitOptions);
		
		if	(singleton)
			throw new Error("HelpWindow is a singleton that cannot be publically instantiated and is only accessible thru the \"helpWindow\" public property.");
			
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		width = 650;
		height = 550;
		
		var boundsRect:Object = Preferences.preferences.getPreference(PREFS_HELP_WINDOW_BOUNDS, new Rectangle(Capabilities.screenResolutionX / 2 - width / 2, Capabilities.screenResolutionY / 2 - height / 2, width, height));
		bounds = windowBounds = new Rectangle(boundsRect.x, boundsRect.y, boundsRect.width, boundsRect.height);
		
		backgroundGradient = createBackgroundGradient()

		helpIcon = new Bitmap(new Icon256(), PixelSnapping.ALWAYS, true);
		helpIcon.scaleX = helpIcon.scaleY = 0.15;
		helpIcon.x = 20;
		helpIcon.y = 25;
		
		helpTitleTextField = createHelpWindowTextField(true);
		helpTitleTextField.width = width;
		helpTitleTextField.x = helpIcon.x + helpIcon.width + 12;
		helpTitleTextField.y = helpIcon.y + helpIcon.height / 2 - helpTitleTextField.height / 2;
		
		helpBodyTextField = createHelpWindowTextField();
		helpBodyTextField.width = width - helpTitleTextField.x * 2;
		helpBodyTextField.x = helpTitleTextField.x;
		helpBodyTextField.y = helpTitleTextField.y + helpTitleTextField.height;
		
		addEventListener(Event.CLOSING, closingWindowEventHandler);
		addEventListener(NativeWindowBoundsEvent.MOVE, windowMoveEventListener);
        
		stage.addChild(backgroundGradient);
		stage.addChild(helpIcon);
		stage.addChild(helpTitleTextField);
		stage.addChild(helpBodyTextField);
		}
		
	//Create Background Gradient
	private function createBackgroundGradient():Shape
		{
		var backgroundMatrix:Matrix = new Matrix();
		backgroundMatrix.createGradientBox(width, height, Math.PI / 2);
		
		var result:Shape = new Shape();
		result.graphics.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0x777777], [1.0, 1.0], [0, 255], backgroundMatrix);
		result.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		result.graphics.endFill();
		
		return result;
		}
		
	//Create Text Field
	private function createHelpWindowTextField(createTitle:Boolean = false):TextField
		{
		var defaultFormat:TextFormat = new TextFormat(DropSwatch.regularFont.fontName, (createTitle) ? 18 : 12, (createTitle) ? 0x111111 : 0x333333);
		
		var style:StyleSheet = new StyleSheet();
		style.setStyle(".bold", {fontFamily: DropSwatch.boldFont.fontName, fontWeight: "bold"});

		var result:TextField = new TextField();
		result.antiAliasType = AntiAliasType.ADVANCED;
		result.autoSize = TextFieldAutoSize.LEFT;
		result.defaultTextFormat = defaultFormat;
		result.embedFonts = true;
		result.multiline = false;
		result.selectable = false;
		result.styleSheet = style;
		result.type = TextFieldType.DYNAMIC;
		result.wordWrap = true;
		
		if	(createTitle)
			result.htmlText = 	"<span class = 'bold'>Drop Swatch Help</span>"
			else
			result.htmlText = 	"\n\n<span class = 'bold'>Instructions:</span>\n\n" +
			
								"1.  Double click/tap canvas to drop new swatch.\n" +
								"2.  Drag, zoom and rotate swatches using common gestures on supported systems.\n" +
								"3.  Single click/tap swatch to edit color and/or texture.\n" +
								"4.  Drag and throw swatches off screen to remove.\n\n\n" +
								
								
								"<span class = 'bold'>Canvas:</span>\n\n" +
								
								"The brightness of the background canvas is customizable via application preferences.\n\n\n" +
								
								
								"<span class = 'bold'>Swatches:</span>\n\n" +
								
								"A:  Alpha value range between 0-255.\n" +
								"R:  Red value range between 0-255.\n" +
								"G:  Green value range between 0-255.\n" +
								"B:  Blue value range between 0-255.\n" +
								"H:  Hexadecimal combined values within a 32-bit 0xAARRGGBB configuration.\n\n\n" +
								
								
								"<span class = 'bold'>Appearance Panel:</span>\n\n" +
								
								"The color of the selected swatch may be altered via clicking/tapping or dragging within either a color wheel or a color slider.  Color sliders also support value easing via click/tap and hold.  " +
								"The texture of the selected swatch may be applied or rotated 90º by clicking/tapping or re-clicking/re-tapping on a texture option respectively.";

		return result;
		}
		
	//Window Move Event Listener
	private function windowMoveEventListener(evt:NativeWindowBoundsEvent):void
		{
		windowBounds = new Rectangle(stage.nativeWindow.x, stage.nativeWindow.y, stage.nativeWindow.width, stage.nativeWindow.height);
		}
		
	//Closing Window Event Handler
	private function closingWindowEventHandler(evt:Event):void
		{
		removeEventListener(Event.CLOSING, closingWindowEventHandler);
		removeEventListener(NativeWindowBoundsEvent.MOVE, windowMoveEventListener);
		
		Preferences.preferences.setPreference(PREFS_HELP_WINDOW_BOUNDS, windowBounds);
		
		singleton = null;
		}

	//Singleton Getter
	public static function get helpWindow():HelpWindow
		{
		if	(!singleton)
			singleton = new HelpWindow();

		return singleton;
		}
	}
}