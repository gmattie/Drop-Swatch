package
{
//Imports
import com.caurina.transitions.Equations;
import com.caurina.transitions.properties.ColorShortcuts;
import com.caurina.transitions.properties.FilterShortcuts;
import com.caurina.transitions.Tweener;
import com.mattie.data.Preferences;
import com.mattie.data.PreferencesItem;
import com.mattie.data.events.PreferencesEvent;
import fl.motion.AdjustColor;
import flash.desktop.NativeApplication;
import flash.display.Bitmap;
import flash.display.BlendMode;
import flash.display.BitmapData;
import flash.display.NativeMenu;
import flash.display.NativeWindow;
import flash.display.PixelSnapping;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.NativeWindowBoundsEvent;
import flash.events.TransformGestureEvent;
import flash.filters.ColorMatrixFilter;
import flash.filters.BlurFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.system.Capabilities;
import flash.text.Font;
import flash.utils.getTimer;

//SWF Metadata Tag
[SWF(backgroundColor = "#000000")]

//Class
public class DropSwatch extends Sprite
	{
	//Constants
	public static const PREFS_MAIN_WINDOW_BOUNDS:String = "prefsMainWindowBounds";
	public static const PREFS_LAUNCH_FULL_SCREEN:String = "prefsLaunchFullScreen";
	public static const PREFS_CANVAS_BRIGHTNESS:String = "prefsCanvasBrightness";
	public static const PREFS_SWATCHES_ARRAY:String = "prefsSwatchesArray"

	public static const DEFAULT_STAGE_WIDTH:uint = 1024;
	public static const DEFAULT_STAGE_HEIGHT:uint = 600;
		
	private static const MIN_WINDOW_WIDTH:uint = 480;
	private static const MIN_WINDOW_HEIGHT:uint = 342;
	private static const BLUR_AMOUNT:uint = 150;
	private static const DEFAULT_BACKGROUND_BRIGHTNESS:int = -60;
	private static const DOUBLE_CLICK_SPEED:Number = 250;
	
	//Fonts
	public static var regularFont:Font = new ApplicationFontRegular();
	public static var boldFont:Font = new ApplicationFontBold();
	public static var swatchFont:Font = new SwatchFont();
	
	//Properties
	public static var controller:DropSwatch;
	public static var deviceIsMobile:Boolean;
	
	public var appearancePanel:AppearancePanel;
	public var preferencesPanel:PreferencesPanel;
	public var selectedSwatch:Swatch;
	public var canvasBrightness:Number;
	
	//Variables
	private var backgroundFillShape:Shape;
	private var backgroundFillBitmapData:BitmapData;
	private var backgroundFill:Bitmap;
	private var backgroundTexture:Shape;
	private var canvas:Sprite;
	private var canvasShader:Shape;
	private var appearancePanelAutoLocation:String;
	private var timerMark:Number;
	private var windowBounds:Rectangle;
	private var shaderIsWhite:Boolean;

	//Constructor
	public function DropSwatch()
		{
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		stage.frameRate = 60;
		
		init();
		}
	
	//Initialization
	private function init():void
		{
		ColorShortcuts.init();
		FilterShortcuts.init();
		
		controller = this;
		Preferences.preferences.load();
		
		if	(NativeWindow.isSupported)
			{
			var boundsRect:Object = Preferences.preferences.getPreference(DropSwatch.PREFS_MAIN_WINDOW_BOUNDS, new Rectangle(Capabilities.screenResolutionX / 2 - stage.stageWidth / 2, Capabilities.screenResolutionY / 2 - stage.stageHeight / 2, stage.stageWidth, stage.stageHeight));
			
			stage.nativeWindow.bounds = windowBounds = new Rectangle(boundsRect.x, boundsRect.y, boundsRect.width, boundsRect.height);
			stage.nativeWindow.minSize = new Point(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT);
			stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.RESIZE, windowResizeEventHandler);
			stage.nativeWindow.addEventListener(NativeWindowBoundsEvent.MOVE, windowMoveEventHandler);
			}			
			
		if	((Capabilities.os.toLowerCase().indexOf("mac") == -1) && (Capabilities.os.toLowerCase().indexOf("windows") == -1) && (Capabilities.os.toLowerCase().indexOf("linux") == -1))
			deviceIsMobile = true;
			
		var adjustColor:AdjustColor = new AdjustColor();
		adjustColor.brightness = canvasBrightness = DEFAULT_BACKGROUND_BRIGHTNESS;
		adjustColor.contrast = 0;
		adjustColor.hue = 0;
		adjustColor.saturation = 0;
		
		var defaultCanvasBrightness:Array = new Array();
		defaultCanvasBrightness = adjustColor.CalculateFinalFlatArray();
		
		backgroundFillShape = new Shape();
		backgroundFillShape.graphics.beginFill(0x7F7F7F, 1.0);
		backgroundFillShape.graphics.drawRect(-(MIN_WINDOW_WIDTH + BLUR_AMOUNT * 2) / 2, -(MIN_WINDOW_HEIGHT + BLUR_AMOUNT * 2) / 2, MIN_WINDOW_WIDTH + BLUR_AMOUNT * 2, MIN_WINDOW_HEIGHT + BLUR_AMOUNT * 2);
		backgroundFillShape.graphics.endFill();
		backgroundFillShape.graphics.beginFill(0xFFFFFF, 1.0);
		backgroundFillShape.graphics.drawEllipse(-MIN_WINDOW_WIDTH * 0.75 / 2, -MIN_WINDOW_HEIGHT * 0.5 / 2, MIN_WINDOW_WIDTH * 0.75, MIN_WINDOW_HEIGHT * 0.5);
		backgroundFillShape.graphics.endFill();
		backgroundFillShape.filters = [new BlurFilter(BLUR_AMOUNT, BLUR_AMOUNT, 3)];

		backgroundFillBitmapData = new BitmapData(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT);
		backgroundFillBitmapData.draw(backgroundFillShape, new Matrix(1, 0, 0, 1, MIN_WINDOW_WIDTH / 2, MIN_WINDOW_HEIGHT / 2));

		backgroundFill = new Bitmap(backgroundFillBitmapData, PixelSnapping.NEVER, true);
		backgroundFill.width = stage.stageWidth;
		backgroundFill.height = stage.stageHeight;
		
		backgroundTexture = new Shape();
		backgroundTexture.graphics.beginBitmapFill(backgroundFillBitmapData = new Background());
		backgroundTexture.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		backgroundTexture.graphics.endFill();
		backgroundTexture.blendMode = BlendMode.MULTIPLY;

		canvas = new Sprite();
		canvas.addChild(backgroundFill);
		canvas.addChild(backgroundTexture);		
		canvas.filters = [new ColorMatrixFilter(defaultCanvasBrightness)];
		
		appearancePanel = new AppearancePanel	(
												Preferences.preferences.getPreference(AppearancePanel.PREFS_PANEL_MODE, AppearancePanel.COLOR_WHEEL_MODE),
												Preferences.preferences.getPreference(AppearancePanel.PREFS_COLOR_WHEEL_SUBMODE, AppearancePanel.COLOR_WHEEL_SUBMODE_LIGHT),
												Preferences.preferences.getPreference(AppearancePanel.PREFS_PANEL_LOCATION, AppearancePanel.LOCATION_AUTO),
												Preferences.preferences.getPreference(AppearancePanel.PREFS_TEXTURE_PANEL_IS_COLLAPSED, true)
												)

		canvasShader = new Shape();
		changeBackgroundShaderColor(0x000000);
		canvasShader.alpha = 0.0;
		
		stage.addEventListener(DropSwatchEvent.BRIGHTNESS, canvasBrightnessEventHandler);
		stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.BRIGHTNESS, null, NaN, null, true, Preferences.preferences.getPreference(DropSwatch.PREFS_CANVAS_BRIGHTNESS, -0.2)));
		
		Swatch.hasRandomColor = Preferences.preferences.getPreference(Swatch.PREFS_RANDOM_SWATCH_COLOR, true);
		Swatch.hasRandomTexture = Preferences.preferences.getPreference(Swatch.PREFS_RANDOM_SWATCH_TEXTURE, true);
		Swatch.showValues = Preferences.preferences.getPreference(Swatch.PREFS_SHOW_SWATCH_VALUES, true);

		addChild(canvas);
		addChild(appearancePanel);
		addChild(canvasShader);

		var savedSwatches:Array = Preferences.preferences.getPreference(DropSwatch.PREFS_SWATCHES_ARRAY, null);

		if	(savedSwatches != null)
			{
			for each	(var savedSwatch:Object in savedSwatches)
						{
						var restoredSwatch:Swatch = new Swatch(savedSwatch)
						restoredSwatch.x = savedSwatch.x;
						restoredSwatch.y = savedSwatch.y;

						addChild(restoredSwatch);
						}
			}
		
		stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownEventHandler);
		stage.addEventListener(DropSwatchEvent.SELECT, selectSwatchEventHandler);
		stage.addEventListener(DropSwatchEvent.DISPOSE, disposeSwatchEventHandler);			
		stage.nativeWindow.addEventListener(Event.CLOSING, applicationExitingEventHandler);

		if	(!deviceIsMobile)
			{
			if	(Preferences.preferences.getPreference(DropSwatch.PREFS_LAUNCH_FULL_SCREEN, false))
				toggleDisplayState();
				
			if	(NativeMenu.isSupported)
				new DesktopMenu();
			}
			else
			{
			preferencesPanel = new PreferencesPanel();
			addChild(preferencesPanel);
			
			if	(Capabilities.os.toLowerCase().indexOf("qnx") != -1)
				new QNXOperatingSystem();
				else
				canvas.addEventListener(TransformGestureEvent.GESTURE_SWIPE, swipeGestureEventHandler);
			}
		}
	
	//Swipe Gesture Event Handler
	private function swipeGestureEventHandler(evt:TransformGestureEvent):void
		{
		evt.stopImmediatePropagation();
		
		if	(evt.offsetY == 1)
			preferencesPanel.show();
		}
	
	//Mouse Down Event Handler
	private function mouseDownEventHandler(evt:MouseEvent):void
		{
		if	(preferencesPanel && preferencesPanel.visible)
			{
			preferencesPanel.hide();
			return;
			}
			
		if	(selectedSwatch)
			Swatch(getChildAt(getChildIndex(selectedSwatch))).deselect();
		
		stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpEventHandler);
		}
		
	//Mouse Up Event Handler
	private function mouseUpEventHandler(evt:MouseEvent):void
		{
		stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpEventHandler);

		if	(timerMark != 0 && getTimer() - timerMark <= DOUBLE_CLICK_SPEED)
			{
			mouseDoubleClickEventHandler(evt);
			timerMark = 0;
			}
			else
			timerMark = getTimer();
		}
		
	//Mouse Double Click Event Handler
	private function mouseDoubleClickEventHandler(evt:MouseEvent):void
		{
		var newSwatch:Swatch = new Swatch();
		newSwatch.x = evt.stageX;
		newSwatch.y = evt.stageY;
		
		addChild(newSwatch);
		}
		
	//Resize Event Handler
	private function windowResizeEventHandler(evt:NativeWindowBoundsEvent):void
		{
		backgroundFill.width = canvasShader.width = stage.stageWidth;
		backgroundFill.height = canvasShader.height = stage.stageHeight;

		backgroundTexture.graphics.clear();
		backgroundTexture.graphics.beginBitmapFill(backgroundFillBitmapData);
		backgroundTexture.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		backgroundTexture.graphics.endFill();
		
		var swatch:Swatch;
		
		for	(var i:uint = 0; i < numChildren; i++)
			if	(Object(getChildAt(i)).constructor == Swatch)
				{
				swatch = Swatch(getChildAt(i));
				swatch.updateStageBounds();
				
				if	(selectedSwatch == swatch && !swatch.stageBounds.intersects(swatch.getBounds(this)))
					swatch.deselect(false);
				}
				
		appearancePanel.layout();

		windowMoveEventHandler(evt);
		}
		
	//Window Move Event Handler
	private function windowMoveEventHandler(evt:NativeWindowBoundsEvent):void
		{
		windowBounds = new Rectangle(stage.nativeWindow.x, stage.nativeWindow.y, stage.nativeWindow.width, stage.nativeWindow.height);
		}
		
	//Selected Swatch Event Handler
	private function selectSwatchEventHandler(evt:DropSwatchEvent):void
		{
		selectedSwatch = evt.swatchTarget;
		
		if	(evt.swatchTarget != null)
			{
			setChildIndex(appearancePanel, getChildIndex(evt.swatchTarget) - 1);
			
			if	(appearancePanel.panelLocation == AppearancePanel.LOCATION_AUTO)
				appearancePanelAutoLocation = (evt.swatchTarget.x <= stage.stageWidth / 2) ? AppearancePanel.LOCATION_RIGHT : AppearancePanel.LOCATION_LEFT;

			appearancePanel.show(appearancePanelAutoLocation);
			}
			else
			appearancePanel.hide();
		}
		
	//Dispose Swatch Event Handler
	private function disposeSwatchEventHandler(evt:DropSwatchEvent):void
		{
		removeChild(evt.swatchTarget);
		}
		
	//Canvas Brightness Event Handler
	private function canvasBrightnessEventHandler(evt:DropSwatchEvent):void
		{
		if	(!shaderIsWhite && evt.canvasBrightness >= 0.0)
			{
			changeBackgroundShaderColor(0xFFFFFFF);
			shaderIsWhite = true;
			}
			else if	(shaderIsWhite && evt.canvasBrightness < 0.0)
					{
					changeBackgroundShaderColor(0x000000);
					shaderIsWhite = false;
					}
					
		canvasBrightness = Math.max(-1.0, Math.min(evt.canvasBrightness, 1.0));
		canvasShader.alpha = Math.abs(canvasBrightness)
		}
		
	//Change Background Shader Color
	private function changeBackgroundShaderColor(color:uint):void
		{
		canvasShader.graphics.clear();
		canvasShader.graphics.beginFill(color, 1.0);
		canvasShader.graphics.drawRect(0, 0, 1, 1);
		canvasShader.graphics.endFill();
		
		canvasShader.width = stage.stageWidth;
		canvasShader.height = stage.stageHeight;
		}

	//Remove All Swatches Event Handler
	private function removeAllSwatches():void
		{
		stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.REMOVE_ALL));
		}
		
	//Application Exiting Event Handler
	private function applicationExitingEventHandler(evt:Event):void
		{
		Preferences.preferences.setPreference(AppearancePanel.PREFS_PANEL_LOCATION, appearancePanel.panelLocation);
		Preferences.preferences.setPreference(AppearancePanel.PREFS_PANEL_MODE, appearancePanel.panelMode);
		Preferences.preferences.setPreference(AppearancePanel.PREFS_COLOR_WHEEL_SUBMODE, appearancePanel.colorWheelSubmode);
		Preferences.preferences.setPreference(AppearancePanel.PREFS_TEXTURE_PANEL_IS_COLLAPSED, appearancePanel.texturePanelIsCollapsed);
		Preferences.preferences.setPreference(Swatch.PREFS_RANDOM_SWATCH_COLOR, Swatch.hasRandomColor);
		Preferences.preferences.setPreference(Swatch.PREFS_RANDOM_SWATCH_TEXTURE, Swatch.hasRandomTexture);
		Preferences.preferences.setPreference(Swatch.PREFS_SHOW_SWATCH_VALUES, Swatch.showValues);

		var swatchesArray:Array = new Array();
		var swatch:Swatch;
		
		for	(var i:uint = 0; i < numChildren; i++)
			if	(Object(getChildAt(i)).constructor == Swatch)
				{
				swatch = Swatch(getChildAt(i));
			
				if	(swatch.stageBounds.intersects(swatch.getBounds(this)))
					swatchesArray.push({x: swatch.x, y: swatch.y, color: swatch.swatchColor, size: swatch.swatchSize, rotation: swatch.swatchRotation, texture: swatch.swatchTexture, textureRotation: swatch.swatchTextureRotation});
					else
					{
					swatch.dispose();
					i--;
					}
				}

		Preferences.preferences.setPreference(DropSwatch.PREFS_SWATCHES_ARRAY, swatchesArray);
		Preferences.preferences.setPreference(DropSwatch.PREFS_CANVAS_BRIGHTNESS, canvasBrightness);
		
		if	(NativeWindow.isSupported)
			{
			Preferences.preferences.setPreference(DropSwatch.PREFS_LAUNCH_FULL_SCREEN, (stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE));
			
			if	(stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE)
				toggleDisplayState();
			
			Preferences.preferences.setPreference(DropSwatch.PREFS_MAIN_WINDOW_BOUNDS, windowBounds);
			
			if	(HelpWindow.windowBounds != null)
				Preferences.preferences.setPreference(HelpWindow.PREFS_HELP_WINDOW_BOUNDS, HelpWindow.windowBounds);
				
			if	(AboutWindow.windowBounds != null)
				Preferences.preferences.setPreference(AboutWindow.PREFS_ABOUT_WINDOW_BOUNDS, AboutWindow.windowBounds);
				
			if	(PreferencesWindow.windowBounds != null)
				Preferences.preferences.setPreference(PreferencesWindow.PREFS_PREFERENCES_WINDOW_BOUNDS, PreferencesWindow.windowBounds);
			}
			
		Preferences.preferences.save();
		
		NativeApplication.nativeApplication.exit();
		}
		
	//Toggle Display State
	public function toggleDisplayState():void
		{
		if	(stage.displayState == StageDisplayState.NORMAL)
			stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			else
			stage.displayState = StageDisplayState.NORMAL;
			
		for	(var i:uint = 0; i < numChildren; i++)
			if	(Object(getChildAt(i)).constructor == Swatch)
				Swatch(getChildAt(i)).updateStageBounds();
		}
	}
}