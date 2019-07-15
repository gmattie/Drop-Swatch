package
{
//Imports
import com.caurina.transitions.Equations;
import com.caurina.transitions.Tweener;
import com.mattie.display.callout.*;
import flash.desktop.NativeApplication;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.AntiAliasType;
import flash.text.Font;
import flash.text.StyleSheet;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.utils.Timer;

//Class
public class PreferencesPanel extends Sprite
	{
	//Constants
	private static const DEFAULT_BRIGHTNESS_SLIDER_CONTROL_WIDTH:uint = 400;
	private static const DEFAULT_SHOW_VALUES_CONTROL_WIDTH:uint = 220;
	private static const DEFAULT_CLEAR_ALL_CONTROL_WIDTH:uint = 172;
	private static const DEFAULT_ABOUT_CONTROL_WIDTH:uint = 132;
	private static const RELEASE_YEAR:int = 2011;
	
	private static const FILTER_AMOUNT:Number = 14.0;
	private static const ANIMATION_DURATION:Number = 0.5;
	private static const ACTIVE_BUTTON_COLOR:Number = 0x555555;
	private static const INACTIVE_BUTTON_COLOR:Number = 0x333333;
	private static const DISABLED_BUTTON_ICON_COLOR:uint = 0x666666;
	private static const SLIDABLE_BUFFER:int = 10;
	
	private static const SHOW_VALUES:String = "Show Values";
	private static const HIDE_VALUES:String = "Hide Values";
	private static const CLEAR_ALL:String = "Clear All";
	private static const ABOUT:String = "About";
	
	//Variables
	private var yScale:Number;
	private var mainFrameHeight:uint;
	private var controlHeight:uint;
	private var mainFrameGap:uint;
	private var buttonsTotalWidth:uint;
	private var buttonsRemainingWidth:uint;
	
	private var brightnessSliderRect:Rectangle;
	private var showValuesRect:Rectangle;
	private var clearAllRect:Rectangle;
	private var aboutRect:Rectangle;

	private var mainFrame:Sprite;
	private var brightnessSlider:BrightnessSlider;
	private var showValuesButton:Sprite;
	private var clearAllButton:Sprite;
	private var aboutButton:Sprite;

	private var aboutCallout:Callout;

	private var defaultFormat:TextFormat;
	private var style:StyleSheet;
	
	private var brightnessSliderTimer:Timer;
	private var brightnessSliderOriginX:Number;
	private var brightnessSliderSign:Sprite;
	private var brightnessSliderSignSibling:Sprite;
	private var brightnessSliderIsSlidable:Boolean;
	private var brightnessSliderUnit:Number;	
	private var canvasBrightness:Number;
	
	//Constructor
	public function PreferencesPanel()
		{
		addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
	//Initialize
	private function init(evt:Event):void
		{
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		yScale = (stage.stageHeight < DropSwatch.DEFAULT_STAGE_HEIGHT) ? stage.stageHeight / DropSwatch.DEFAULT_STAGE_HEIGHT : 1.0;
		mainFrameHeight = 100 * yScale;
		controlHeight = 60 * yScale;
		mainFrameGap = mainFrameHeight / 5;
		buttonsTotalWidth = DEFAULT_SHOW_VALUES_CONTROL_WIDTH + DEFAULT_CLEAR_ALL_CONTROL_WIDTH + DEFAULT_ABOUT_CONTROL_WIDTH;
		buttonsRemainingWidth = stage.stageWidth - (DEFAULT_BRIGHTNESS_SLIDER_CONTROL_WIDTH * yScale) - (mainFrameGap * 5);
		
		brightnessSliderRect = new Rectangle(mainFrameGap, mainFrameGap, DEFAULT_BRIGHTNESS_SLIDER_CONTROL_WIDTH * yScale, controlHeight);
		showValuesRect = new Rectangle(brightnessSliderRect.x + brightnessSliderRect.width + mainFrameGap, mainFrameGap, buttonsRemainingWidth * (1 / (buttonsTotalWidth / DEFAULT_SHOW_VALUES_CONTROL_WIDTH)), controlHeight);
		clearAllRect = new Rectangle(showValuesRect.x + showValuesRect.width + mainFrameGap, mainFrameGap, buttonsRemainingWidth * (1 / (buttonsTotalWidth / DEFAULT_CLEAR_ALL_CONTROL_WIDTH)), controlHeight);
		aboutRect = new Rectangle(clearAllRect.x + clearAllRect.width + mainFrameGap, mainFrameGap, buttonsRemainingWidth * (1 / (buttonsTotalWidth / DEFAULT_ABOUT_CONTROL_WIDTH)), controlHeight);

		defaultFormat = new TextFormat(DropSwatch.regularFont.fontName, Math.floor(26 * yScale), 0xFFFFFF, true, null, null, null, null, TextFormatAlign.CENTER);
		
		mainFrame = new Sprite();
		mainFrame.graphics.beginFill(0x4D4D4D, 1.0);
		mainFrame.graphics.drawRect(0, 0, stage.stageWidth, mainFrameHeight);
		mainFrame.graphics.drawRect(brightnessSliderRect.x, brightnessSliderRect.y, brightnessSliderRect.width, brightnessSliderRect.height);
		mainFrame.graphics.drawRect(showValuesRect.x, showValuesRect.y, showValuesRect.width, showValuesRect.height);
		mainFrame.graphics.drawRect(clearAllRect.x, clearAllRect.y, clearAllRect.width, clearAllRect.height);
		mainFrame.graphics.drawRect(aboutRect.x, aboutRect.y, aboutRect.width, aboutRect.height);
		mainFrame.graphics.endFill();
		mainFrame.filters =	[new DropShadowFilter(0, 90, 0x000000, 1.0, FILTER_AMOUNT * yScale, FILTER_AMOUNT * yScale, 1.0, 3)];
		
		brightnessSlider = new BrightnessSlider();
		brightnessSlider.x = brightnessSliderRect.x - 1;
		brightnessSlider.y = brightnessSliderRect.y - 1;
		brightnessSlider.width = brightnessSliderRect.width + 2;
		brightnessSlider.height = brightnessSliderRect.height + 2;
		
		brightnessSliderUnit = 1 / (brightnessSlider.width / 2);
		
		showValuesButton = createPreferencesPanelButton(showValuesRect, (Swatch.showValues) ? HIDE_VALUES : SHOW_VALUES);
		clearAllButton = createPreferencesPanelButton(clearAllRect, CLEAR_ALL);
		aboutButton = createPreferencesPanelButton(aboutRect, ABOUT);
		
		aboutCallout = createAboutCallout();
		aboutCallout.x = aboutRect.x + aboutRect.width / 2;
		aboutCallout.y = mainFrame.height;
		aboutCallout.roundCorners = (stage.stageWidth < DropSwatch.DEFAULT_STAGE_WIDTH) ? Math.round(50.0 / DropSwatch.DEFAULT_STAGE_WIDTH * stage.stageWidth) : 50.0;
		aboutCallout.stemAlign = (1.0 + 1 / ((aboutCallout.width / 2) / (aboutCallout.stemWidth / 2))) - (1 / ((aboutCallout.width / 2) / (aboutRect.width / 2)));
		aboutCallout.filters = [new DropShadowFilter(0, 90, 0x000000, 1.0, FILTER_AMOUNT * yScale, FILTER_AMOUNT * yScale, 1.0, 3)];
		aboutCallout.alpha = 0.0;
		aboutCallout.visible = false;
				
		for each	(var mouseDownTarget:Sprite in					[
																	mainFrame,
																	brightnessSlider,
																	showValuesButton,
																	clearAllButton,
																	aboutButton,
																	aboutCallout
																	])
																	mouseDownTarget.addEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler);
														
		for each	(var mouseDisabledTarget:InteractiveObject in	[
																	brightnessSlider.plus,
																	brightnessSlider.minus,
																	showValuesButton.getChildAt(1),
																	clearAllButton.getChildAt(1),
																	aboutButton.getChildAt(1)
																	])
																	mouseDisabledTarget.mouseEnabled = false;
													
		for each	(var glowTarget:DisplayObject in				[
																	brightnessSlider.plus,
																	brightnessSlider.minus,
																	showValuesButton.getChildAt(1),
																	clearAllButton.getChildAt(1),
																	aboutButton.getChildAt(1)
																	])
																	glowTarget.filters = [new GlowFilter(0xFFFFFF, 0.0, FILTER_AMOUNT * yScale, FILTER_AMOUNT * yScale, 2, 3)];
															
		addChild(brightnessSlider);
		addChild(showValuesButton);
		addChild(clearAllButton);
		addChild(aboutButton);
		addChild(aboutCallout);
		addChild(mainFrame);
		
		y = -(mainFrame.height + FILTER_AMOUNT * yScale);
		visible = false;
		}
		
	//Create About Panel
	private function createAboutCallout():Callout
		{
		var aboutCalloutContent:Sprite = new Sprite();
		aboutCalloutContent.graphics.beginFill(0x00FF00, 0.0);
		aboutCalloutContent.graphics.drawRect(0, 0, 460, 237);
		aboutCalloutContent.graphics.endFill();
		
		var aboutIcon:Bitmap = new Bitmap(new Icon256(), PixelSnapping.AUTO, true);
		aboutIcon.scaleX = aboutIcon.scaleY = 0.5;

		var aboutTextFormat:TextFormat = new TextFormat(DropSwatch.regularFont.fontName, 14, 0xFFFFFF);
		var aboutTextStyle:StyleSheet = new StyleSheet();
		aboutTextStyle.setStyle(".bold", {fontFamily: DropSwatch.boldFont.fontName, fontWeight: "bold", fontSize: 22});

		var aboutText:TextField = new TextField();
		aboutText.antiAliasType = AntiAliasType.ADVANCED;
		aboutText.autoSize = TextFieldAutoSize.LEFT;
		aboutText.defaultTextFormat = aboutTextFormat;
		aboutText.embedFonts = true;
		aboutText.multiline = false;
		aboutText.selectable = false;
		aboutText.styleSheet = aboutTextStyle;
		aboutText.type = TextFieldType.DYNAMIC;

		var descriptorFile:XML = NativeApplication.nativeApplication.applicationDescriptor;
		var nameSpace:Namespace = descriptorFile.namespace();
		var currentYear:Number = new Date().getFullYear();
		var copyrightYear:String = (currentYear == RELEASE_YEAR) ? RELEASE_YEAR.toString() : RELEASE_YEAR.toString() + "-" + currentYear.toString();
	
		aboutText.htmlText =	"<span class = 'bold'>Drop Swatch</span> " +
								"version " + descriptorFile.nameSpace::versionNumber + "\n\n" +
								"Copyright © " + copyrightYear + " Geoffrey Mattie\n" +
								"Montréal, Canada\n" +
								"<a href = 'http://www.geoffreymattie.com'>www.geoffreymattie.com</a>\n\n";
		
		var gap:Number = (aboutCalloutContent.width - aboutIcon.width - aboutText.width) / 3;
		
		aboutIcon.x = gap;
		aboutIcon.y = aboutCalloutContent.height / 2 - aboutIcon.height / 2;
		aboutText.x = aboutIcon.x + aboutIcon.width + gap - 5;
		aboutText.y = aboutIcon.y + aboutIcon.height / 2 - aboutText.height / 2 + 10;
		
		aboutCalloutContent.addChild(aboutIcon);
		aboutCalloutContent.addChild(aboutText);
		
		return new Callout(aboutCalloutContent, 0x000000, 0.4, 2.0, 0x000000, 1.0, 0.0, mainFrameGap * 2, mainFrameGap, -1.0, CalloutStemStyle.ISOSCELES, CalloutStemLocation.TOP, true, false);
		}
		
	//Create Preferences Panel Button
	private function createPreferencesPanelButton(bounds:Rectangle, buttonLabel:String):Sprite
		{
		var button:Sprite = new Sprite();
		button.graphics.beginFill(INACTIVE_BUTTON_COLOR, 1.0);
		button.graphics.drawRect(0, 0, bounds.width + 2, bounds.height + 2);
		button.graphics.endFill();

		var label:TextField = new TextField();
		label.antiAliasType = AntiAliasType.ADVANCED;
		label.autoSize = TextFieldAutoSize.CENTER;
		label.defaultTextFormat = defaultFormat;
		label.embedFonts = true;
		label.multiline = false;
		label.selectable = false;
		label.type = TextFieldType.DYNAMIC;
		label.text = buttonLabel;
		label.x = button.width / 2 - label.width / 2;
		label.y = button.height / 2 - label.height / 2;
		
		var result:Sprite = new Sprite();
		result.addChild(button);
		result.addChild(label);
		result.x = bounds.x - 1;
		result.y = bounds.y - 1;
		
		return result;
		}
		
	//Mouse Event Handler
	private function mouseEventHandler(evt:MouseEvent):void
		{
		evt.stopImmediatePropagation();
		
		if	(evt.currentTarget != mainFrame && evt.currentTarget != aboutCallout)
			if	(evt.currentTarget == brightnessSlider)
				preferencesSliderMouseEventHandler(evt);
				else
				preferencesButtonMouseEventHandler(evt)
		}
		
	//Preferences Slider Mouse Event Handler
	private function preferencesSliderMouseEventHandler(evt:MouseEvent):void
		{
		switch	(evt.type)
				{
				case MouseEvent.MOUSE_DOWN:		brightnessSliderSign = (evt.localX >= brightnessSlider.width / 2) ? brightnessSlider.plus : brightnessSlider.minus;
												brightnessSliderSignSibling = (evt.localX >= brightnessSlider.width / 2) ? brightnessSlider.minus : brightnessSlider.plus;
				
												brightnessSlider.addEventListener(MouseEvent.MOUSE_MOVE, preferencesSliderMouseEventHandler);
												brightnessSlider.addEventListener(MouseEvent.MOUSE_UP, preferencesSliderMouseEventHandler);
												stage.addEventListener(MouseEvent.MOUSE_UP, preferencesSliderMouseEventHandler);
												
												brightnessSliderTimer = new Timer(400);
												brightnessSliderTimer.addEventListener(TimerEvent.TIMER, brightnessSliderTimerEventHandler);
												brightnessSliderTimer.start();
												
												brightnessSliderOriginX = evt.localX;
												
												Tweener.addTween(brightnessSlider.light, {time: 0.0, alpha: 0.5});
												Tweener.addTween(brightnessSliderSign, {time: 0.0, alpha: 1.0, _Glow_alpha: 1.0});
												
												break;
												
				case MouseEvent.MOUSE_MOVE:		if	(brightnessSliderIsSlidable)
													stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.BRIGHTNESS, null, NaN, null, true, canvasBrightness + Math.round((brightnessSliderOriginX - evt.localX) * -1) * brightnessSliderUnit));
													else
													{
													if	(Math.abs(evt.localX - brightnessSliderOriginX) >= SLIDABLE_BUFFER)
														{
														brightnessSliderTimer.removeEventListener(TimerEvent.TIMER, brightnessSliderTimerEventHandler);
														brightnessSliderTimer.stop();
														brightnessSliderTimer = null;
														
														brightnessSliderOriginX = evt.localX;
														brightnessSliderIsSlidable = true;
														
														canvasBrightness = DropSwatch.controller.canvasBrightness;
														
														Tweener.addTween(brightnessSliderSignSibling, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 1.0, alpha: 1.0});
														}
													}
				
												break;
												
				case MouseEvent.MOUSE_UP:		brightnessSlider.removeEventListener(MouseEvent.MOUSE_MOVE, preferencesSliderMouseEventHandler);
												brightnessSlider.removeEventListener(MouseEvent.MOUSE_UP, preferencesSliderMouseEventHandler);
												stage.removeEventListener(MouseEvent.MOUSE_UP, preferencesSliderMouseEventHandler);
												
												if	(brightnessSliderTimer != null)
													{
													brightnessSliderTimer.removeEventListener(TimerEvent.TIMER, brightnessSliderTimerEventHandler);
													brightnessSliderTimer.stop();
													brightnessSliderTimer = null;
													}
												
												Tweener.addTween(brightnessSlider.light, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, alpha: 0.0});
												
												for each	(var sign:Object in [brightnessSliderSign, brightnessSliderSignSibling])
															Tweener.addTween(sign, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0, alpha: 0.2});
												
												if	(evt.currentTarget != stage && brightnessSliderIsSlidable == false)
													touchBrightnessSliderEventDisptacher(brightnessSliderSign);
													else
													brightnessSliderIsSlidable = false;
				}
		}
		
	//Slider Timer Event Handler
	private function brightnessSliderTimerEventHandler(evt:TimerEvent):void
		{
		if	(evt.currentTarget.delay == 1000)	evt.currentTarget.delay = 200;
		if	(evt.currentTarget.delay > 40)		evt.currentTarget.delay -= 10;
			
		touchBrightnessSliderEventDisptacher(brightnessSliderSign);
		}
		
	//Touch Brightness Slider Event Dispatcher
	private function touchBrightnessSliderEventDisptacher(brightnessSliderSign:Object):void
		{
		switch	(brightnessSliderSign)
				{
				case brightnessSlider.minus:	stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.BRIGHTNESS, null, NaN, null, true, Math.max(-1.0, Math.min(DropSwatch.controller.canvasBrightness - 0.1, 1.0))));	break;
				case brightnessSlider.plus:		stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.BRIGHTNESS, null, NaN, null, true, Math.max(-1.0, Math.min(DropSwatch.controller.canvasBrightness + 0.1, 1.0))));
				}
		}
		
	//Preferences Button Mouse Event Handler
	private function preferencesButtonMouseEventHandler(evt:MouseEvent):void
		{
		switch	(evt.type)
				{
				case MouseEvent.MOUSE_DOWN:		if	(!Tweener.isTweening(evt.currentTarget.getChildAt(0)) && !Tweener.isTweening(evt.currentTarget.getChildAt(1)))
													{
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_OUT, preferencesButtonMouseEventHandler);
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_UP, preferencesButtonMouseEventHandler);
													
													Tweener.addTween(evt.currentTarget.getChildAt(0), {time: 0.0, _color: ACTIVE_BUTTON_COLOR});
													Tweener.addTween(evt.currentTarget.getChildAt(1), {time: 0.0, _Glow_alpha: 1.0});
													}
													
												break;
												
				case MouseEvent.MOUSE_OUT:		evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, preferencesButtonMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, preferencesButtonMouseEventHandler);
												
												Tweener.addTween(evt.currentTarget.getChildAt(0), {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: INACTIVE_BUTTON_COLOR});
												Tweener.addTween(evt.currentTarget.getChildAt(1), {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
												
												break;
												
				case MouseEvent.MOUSE_UP:		evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, preferencesButtonMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, preferencesButtonMouseEventHandler);
												
												switch	(evt.currentTarget)
														{
														case showValuesButton:		stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.VALUES, null, NaN, null, (Swatch.showValues) ? false : true));
																					TextField(showValuesButton.getChildAt(1)).text = (Swatch.showValues) ? HIDE_VALUES : SHOW_VALUES;
																					break;
																					
														case clearAllButton:		stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.REMOVE_ALL));
																					Tweener.addTween(clearAllButton.getChildAt(1), {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: DISABLED_BUTTON_ICON_COLOR});
																					clearAllButton.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler);
																					Tweener.addTween(showValuesButton.getChildAt(1), {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: DISABLED_BUTTON_ICON_COLOR});
																					showValuesButton.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler);
																					break;
																					
														case aboutButton:			toggleAboutPanel();
														}
												
												Tweener.addTween(evt.currentTarget.getChildAt(0), {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: INACTIVE_BUTTON_COLOR});
												Tweener.addTween(evt.currentTarget.getChildAt(1), {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
				}
		}
		
	//Toggle About Panel
	private function toggleAboutPanel():void
		{
		if	(!Tweener.isTweening(aboutCallout))
			{
			if	(aboutCallout.visible)
				Tweener.addTween(aboutCallout, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, y: mainFrame.height, alpha: 0.0, onComplete: function(){aboutCallout.visible = false}});
				else
				{
				aboutCallout.visible = true;
				Tweener.addTween(aboutCallout, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, y: mainFrame.height + mainFrameGap, alpha: 1.0});
				}
			}
		}
		
	//Toggle Buttons Ability
	private function toggleButtonsAbility():void
		{
		for	(var i:uint = 0; i < DropSwatch.controller.numChildren; i++)
			if	(Object(DropSwatch.controller.getChildAt(i)).constructor == Swatch)
				{
				Tweener.addTween(showValuesButton.getChildAt(1), {time: 0.0, _color: 0xFFFFFF});
				showValuesButton.addEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler);
				
				Tweener.addTween(clearAllButton.getChildAt(1), {time: 0.0, _color: 0xFFFFFF});
				clearAllButton.addEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler);
				
				return;
				}

		Tweener.addTween(showValuesButton.getChildAt(1), {time: 0.0, _color: DISABLED_BUTTON_ICON_COLOR});
		showValuesButton.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler);
		
		Tweener.addTween(clearAllButton.getChildAt(1), {time: 0.0, _color: DISABLED_BUTTON_ICON_COLOR});
		clearAllButton.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler);
		}
		
	//Show
	public function show():void
		{
		if	(DropSwatch.controller.selectedSwatch)
			{
			Swatch(DropSwatch.controller.getChildAt(DropSwatch.controller.getChildIndex(DropSwatch.controller.selectedSwatch))).deselect();
			return;
			}
			
		if	(!Tweener.isTweening(this) && visible == false)
			{
			DropSwatch.controller.addChild(this);
			toggleButtonsAbility();
			visible = true;
			Tweener.addTween(this, {time: ANIMATION_DURATION, y: 0});
			}
		}
		
	//Hide
	public function hide():void
		{
		if	(!Tweener.isTweening(this) && visible == true)
			{
			if	(aboutCallout.visible)
				toggleAboutPanel();
				
			Tweener.addTween(this, {time: ANIMATION_DURATION, y: -(mainFrame.height + FILTER_AMOUNT * yScale), onComplete: function(){visible = false}});
			}
		}
	}
}



//to do still:
//1.  make about panel
//2.  animate show/hide preferences panel
//3.  swipe down for QNX
//4.  gear icon in top left corner for non QNX mobile










