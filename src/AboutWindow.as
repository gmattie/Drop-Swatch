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
import flash.text.TextFormatAlign;

//Class
public final class AboutWindow extends NativeWindow
	{
	//Constants
	public static const PREFS_ABOUT_WINDOW_BOUNDS:String = "prefsAboutWindowBounds";
	
	private static const RELEASE_YEAR:int = 2011;

	//Properties
	public static var windowBounds:Rectangle;
		
	private static var singleton:AboutWindow;
	
	//Variables
	private var aboutWindow:NativeWindow;
	private var backgroundGradient:Shape;
	private var aboutIcon:Bitmap;
	private var aboutTitleTextField:TextField;
	private var aboutBodyTextField:TextField;

	//Constructor
	public function AboutWindow()
		{
		var windowInitOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
		windowInitOptions.maximizable = false;
		windowInitOptions.minimizable = false;
		windowInitOptions.resizable = false;
		
		super(windowInitOptions);
		
		if	(singleton)
			throw new Error("AboutWindow is a singleton that cannot be publically instantiated and is only accessible thru the \"aboutWindow\" public property.");
			
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		width = 380;
		height = 405;
		
		var boundsRect:Object = Preferences.preferences.getPreference(PREFS_ABOUT_WINDOW_BOUNDS, new Rectangle(Capabilities.screenResolutionX / 2 - width / 2, Capabilities.screenResolutionY / 2 - height / 2, width, height));
		bounds = windowBounds = new Rectangle(boundsRect.x, boundsRect.y, boundsRect.width, boundsRect.height);
		
		backgroundGradient = createBackgroundGradient();

		aboutIcon = new Bitmap(new Icon256());
		aboutIcon.x = stage.stageWidth / 2 - aboutIcon.width / 2;
		
		aboutTitleTextField = createAboutWindowTextField(true);
		aboutTitleTextField.x = stage.stageWidth / 2 - aboutTitleTextField.width / 2;
		aboutTitleTextField.y = aboutIcon.y + aboutIcon.height + 10;
		
		aboutBodyTextField = createAboutWindowTextField();
		aboutBodyTextField.x = stage.stageWidth / 2 - aboutBodyTextField.width / 2;
		aboutBodyTextField.y = aboutTitleTextField.y + aboutTitleTextField.height - 6;
		
		addEventListener(Event.CLOSING, closingWindowEventHandler);
		addEventListener(NativeWindowBoundsEvent.MOVE, windowMoveEventListener);
        
		stage.addChild(backgroundGradient);
		stage.addChild(aboutIcon);
		stage.addChild(aboutTitleTextField);
		stage.addChild(aboutBodyTextField);
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
	private function createAboutWindowTextField(createTitle:Boolean = false):TextField
		{
		var defaultFormat:TextFormat = new TextFormat(DropSwatch.regularFont.fontName, (createTitle) ? 18 : 12, (createTitle) ? 0x111111 : 0x333333, null, null, null, null, null, TextFormatAlign.CENTER);
		
		var style:StyleSheet = new StyleSheet();
		style.setStyle(".bold", {fontFamily: DropSwatch.boldFont.fontName, fontWeight: "bold"});

		var result:TextField = new TextField();
		result.antiAliasType = AntiAliasType.ADVANCED;
		result.autoSize = TextFieldAutoSize.CENTER;
		result.defaultTextFormat = defaultFormat;
		result.embedFonts = true;
		result.multiline = false;
		result.selectable = false;
		result.styleSheet = style;
		result.type = TextFieldType.DYNAMIC;

		if	(createTitle)
			result.htmlText = 	"<span class = 'bold'>Drop Swatch</span>"
			else
			{
			var descriptorFile:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var nameSpace:Namespace = descriptorFile.namespace();
			var currentYear:Number = new Date().getFullYear();
			var copyrightYear:String = (currentYear == RELEASE_YEAR) ? RELEASE_YEAR.toString() : RELEASE_YEAR.toString() + "-" + currentYear.toString();
		
			result.htmlText =	"Version " + descriptorFile.nameSpace::versionNumber + "\n\n" +
								"Copyright © " + copyrightYear + " Geoffrey Mattie\n" +
								"Montréal, Canada\n" +
								"<a href = 'http://www.geoffreymattie.com'>www.geoffreymattie.com</a>";
			}

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
		
		Preferences.preferences.setPreference(PREFS_ABOUT_WINDOW_BOUNDS, windowBounds);
		
		singleton = null;
		}

	//Singleton Getter
	public static function get aboutWindow():AboutWindow
		{
		if	(!singleton)
			singleton = new AboutWindow();

		return singleton;
		}
	}
}