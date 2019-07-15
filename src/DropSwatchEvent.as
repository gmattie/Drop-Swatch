package
{
//Imports
import flash.display.Sprite;
import flash.events.Event;

//Class
public class DropSwatchEvent extends Event
	{
	//Constants
	public static const SELECT:String = "selected";
	public static const COLOR:String = "color";
	public static const TEXTURE:String = "texture";
	public static const VALUES:String = "values";
	public static const BRIGHTNESS:String = "brightness"
	public static const REMOVE_ALL:String = "removeAll";
	public static const DISPOSE:String = "dispose";

	//Variables
	public var swatchTarget:Swatch;
	public var swatchColor:Number;
	public var swatchTexture:String;
	public var swatchValues:Boolean;
	public var canvasBrightness:Number;

	//Constructor
	public function DropSwatchEvent(type:String, swatchTarget:Swatch = null, swatchColor:Number = NaN, swatchTexture:String = null, swatchValues:Boolean = true, canvasBrightness:Number = 0.0) 
		{
		super(type);
		
		this.swatchTarget = swatchTarget;
		this.swatchColor = swatchColor;
		this.swatchTexture = swatchTexture;
		this.swatchValues = swatchValues;
		this.canvasBrightness = canvasBrightness;
		}
	
	//Override clone
	public override function clone():Event
		{
		return new DropSwatchEvent(type, swatchTarget, swatchColor, swatchTexture, swatchValues, canvasBrightness);
		}
		
	//Override toString
	public override function toString():String
		{
		return formatToString("DropSwatchEvent", "type", "swatchTarget", "swatchColor", "swatchTexture", "swatchValues", "canvasBrightness");
		}
	}
}