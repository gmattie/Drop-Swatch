package
{
//Imports
import com.mattie.data.Preferences;
import fl.controls.RadioButton;
import fl.controls.RadioButtonGroup;
import fl.controls.Slider;
import fl.events.SliderEvent;
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
import flash.events.MouseEvent;
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
public final class PreferencesWindow extends NativeWindow
	{
	//Constants
	public static const PREFS_PREFERENCES_WINDOW_BOUNDS:String = "prefsPreferencesWindowBounds";
	
	//Properties
	public static var windowBounds:Rectangle;
	
	private static var singleton:PreferencesWindow;
	
	//Variables
	private var preferencesWindow:NativeWindow;
	private var backgroundGradient:Shape;
	private var preferencesIcon:Bitmap;
	private var preferencesTitleTextField:TextField;
	private var preferencesBodyTextField:TextField;
	private var brightnessSlider:Slider;
	private var brightnessSliderTrack:Shape;
	private var brightnessSliderTrackMatrix:Matrix;
	private var groupPanelPosition:RadioButtonGroup;
	private var groupSwatchColor:RadioButtonGroup;
	private var groupSwatchTexture:RadioButtonGroup;
	private var radioPanelLeft:RadioButton;
	private var radioPanelRight:RadioButton;
	private var radioPanelAuto:RadioButton;
	private var radioPreviousSwatchColor:RadioButton;
	private var radioRandomColor:RadioButton;
	private var radioPreviousSwatchTexture:RadioButton;
	private var radioRandomTexture:RadioButton;
	private var radioButtonTextFormat:TextFormat;

	//Constructor
	public function PreferencesWindow()
		{
		var windowInitOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
		windowInitOptions.maximizable = false;
		windowInitOptions.minimizable = false;
		windowInitOptions.resizable = false;
		
		super(windowInitOptions);
		
		if	(singleton)
			throw new Error("PreferencesWindow is a singleton that cannot be publically instantiated and is only accessible thru the \"preferencesWindow\" public property.");
			
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		width = 520;
		height = 375;

		var boundsRect:Object = Preferences.preferences.getPreference(PREFS_PREFERENCES_WINDOW_BOUNDS, new Rectangle(Capabilities.screenResolutionX / 2 - width / 2, Capabilities.screenResolutionY / 2 - height / 2, width, height));
		bounds = windowBounds = new Rectangle(boundsRect.x, boundsRect.y, boundsRect.width, boundsRect.height);
		
		backgroundGradient = createBackgroundGradient();

		preferencesIcon = new Bitmap(new Icon256(), PixelSnapping.ALWAYS, true);
		preferencesIcon.scaleX = preferencesIcon.scaleY = 0.15;
		preferencesIcon.x = 20;
		preferencesIcon.y = 25;
		
		preferencesTitleTextField = createPreferencesWindowTextField(true);
		preferencesTitleTextField.x = preferencesIcon.x + preferencesIcon.width + 12;
		preferencesTitleTextField.y = preferencesIcon.y + preferencesIcon.height / 2 - preferencesTitleTextField.height / 2;
		
		preferencesBodyTextField = createPreferencesWindowTextField();
		preferencesBodyTextField.x = preferencesTitleTextField.x + 2;
		preferencesBodyTextField.y = preferencesTitleTextField.y + preferencesTitleTextField.height;
		
		groupPanelPosition = new RadioButtonGroup("PanelPositionGroup");
		groupSwatchColor = new RadioButtonGroup("SwatchColorGroup");
		groupSwatchTexture = new RadioButtonGroup("SwatchTextureGroup");
		
		radioPanelLeft = createPreferenceRadioButton("Left", 270, 83, (DropSwatch.controller.appearancePanel.panelLocation == AppearancePanel.LOCATION_LEFT), groupPanelPosition);
		radioPanelRight = createPreferenceRadioButton("Right", 270, 103, (DropSwatch.controller.appearancePanel.panelLocation == AppearancePanel.LOCATION_RIGHT), groupPanelPosition);
		radioPanelAuto = createPreferenceRadioButton("Auto", 270, 123, (DropSwatch.controller.appearancePanel.panelLocation == AppearancePanel.LOCATION_AUTO), groupPanelPosition);

		radioPreviousSwatchColor = createPreferenceRadioButton("Previously Selected Color", 270, 167, (Swatch.hasRandomColor == false), groupSwatchColor);
		radioRandomColor = createPreferenceRadioButton("Random Color", 270, 187, (Swatch.hasRandomColor == true), groupSwatchColor);
		radioPreviousSwatchTexture = createPreferenceRadioButton("Previously Selected Texture", 270, 227, (Swatch.hasRandomTexture == false), groupSwatchTexture);
		radioRandomTexture = createPreferenceRadioButton("Random Texture", 270, 247, (Swatch.hasRandomTexture == true), groupSwatchTexture);
		
		brightnessSliderTrackMatrix = new Matrix();
		brightnessSliderTrackMatrix.createGradientBox(212, 11, Math.PI / 2);
		
		brightnessSliderTrack = new Shape();
		brightnessSliderTrack.graphics.beginGradientFill(GradientType.LINEAR, [0x666666, 0xFFFFFF], [0.75, 0.4], [0, 255], brightnessSliderTrackMatrix);
		brightnessSliderTrack.graphics.drawRoundRect(0, 0, 212, 11, 14);
		brightnessSliderTrack.graphics.endFill();
		brightnessSliderTrack.x = 276;
		brightnessSliderTrack.y = 300;		
		
		brightnessSlider = createPreferenceWindowSlider(-100, 100, DropSwatch.controller.canvasBrightness * 100, 200);
		brightnessSlider.x = 282;
		brightnessSlider.y = 304;
		brightnessSlider.addEventListener(SliderEvent.CHANGE, brightnessSliderEventHandler);
		
		addEventListener(Event.CLOSING, closingWindowEventHandler);
		addEventListener(NativeWindowBoundsEvent.MOVE, windowMoveEventListener);

		stage.addChild(backgroundGradient);
		stage.addChild(preferencesIcon);
		stage.addChild(preferencesTitleTextField);
		stage.addChild(preferencesBodyTextField);
		stage.addChild(radioPanelLeft);
		stage.addChild(radioPanelRight);
		stage.addChild(radioPanelAuto);
		stage.addChild(radioPreviousSwatchColor);
		stage.addChild(radioRandomColor);
		stage.addChild(radioPreviousSwatchTexture);
		stage.addChild(radioRandomTexture);
		stage.addChild(brightnessSliderTrack);
		stage.addChild(brightnessSlider);
		}
		
	//Create Preference Radio Button
	private function createPreferenceRadioButton(label:String, x:int, y:int, selected:Boolean, group:RadioButtonGroup):RadioButton
		{
		if	(radioButtonTextFormat == null)
			radioButtonTextFormat = new TextFormat(DropSwatch.regularFont.fontName, 12, 0x555555);
			
		var result:RadioButton = new RadioButton();
		result.setStyle("textFormat", radioButtonTextFormat);
		result.label = label;
		result.x = x;
		result.y = y;
		result.selected = selected;
		result.width = 200;
		result.addEventListener(MouseEvent.CLICK, mouseClickEventHandler);
		
		group.addRadioButton(result);
		
		return result;
		}
		
	//Create Preference Wiindow Slider
	private function createPreferenceWindowSlider(minimum:int, maximum:int, value:int, width:int):Slider
		{
		var result:Slider = new Slider();
		result.minimum = minimum;
		result.maximum = maximum;
		result.liveDragging = true;
		result.value = value;
		result.width = width;
		
		return result;
		}
	
	//Brightness Slider Event Handler
	private function brightnessSliderEventHandler(evt:SliderEvent):void
		{
		DropSwatch.controller.stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.BRIGHTNESS, null, NaN, null, true, evt.value / 100));
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
	private function createPreferencesWindowTextField(createTitle:Boolean = false):TextField
		{
		var defaultFormat:TextFormat = new TextFormat(DropSwatch.regularFont.fontName, (createTitle) ? 18 : 12, (createTitle) ? 0x111111 : 0x333333, null, null, null, null, null, (createTitle) ? TextFormatAlign.LEFT : TextFormatAlign.RIGHT);
		
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
		
		if	(createTitle)
			result.htmlText = 	"<span class = 'bold'>Drop Swatch Preferences</span>"
			else
			result.htmlText = 	"\n\n" +
								"<span class = 'bold'>Appearance Panel Position:</span>\n\n\n\n\n\n" +
								"<span class = 'bold'>New Swatches:</span>\n\n\n\n\n\n\n\n\n" +
								"<span class = 'bold'>Canvas Brightness:</span>";

		return result;
		}
		
	//Mouse Click Event Handler
	private function mouseClickEventHandler(evt:MouseEvent):void
		{
		switch	(evt.currentTarget)
				{
				case radioPanelLeft:				DropSwatch.controller.appearancePanel.panelLocation = AppearancePanel.LOCATION_LEFT;		break;
				case radioPanelRight:				DropSwatch.controller.appearancePanel.panelLocation = AppearancePanel.LOCATION_RIGHT;		break;
				case radioPanelAuto:				DropSwatch.controller.appearancePanel.panelLocation = AppearancePanel.LOCATION_AUTO;		break;
				case radioPreviousSwatchColor:		Swatch.hasRandomColor = false;																break;
				case radioRandomColor:				Swatch.hasRandomColor = true;																break;
				case radioPreviousSwatchTexture:	Swatch.hasRandomTexture = false;															break;
				case radioRandomTexture:			Swatch.hasRandomTexture	= true;
				}
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
		brightnessSlider.removeEventListener(SliderEvent.CHANGE, brightnessSliderEventHandler);
		
		Preferences.preferences.setPreference(PREFS_PREFERENCES_WINDOW_BOUNDS, windowBounds);
		Preferences.preferences.setPreference(DropSwatch.PREFS_CANVAS_BRIGHTNESS, brightnessSlider.value / 100);
		
		singleton = null;
		}

	//Singleton Getter
	public static function get preferencesWindow():PreferencesWindow
		{
		if	(!singleton)
			singleton = new PreferencesWindow();

		return singleton;
		}
	}
}