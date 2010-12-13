/*
 * Copyright (c) 2007-2009-2010 the original author or authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
package org.as3commons.reflect {
	import flash.system.ApplicationDomain;

	import org.as3commons.lang.HashArray;

	/**
	 * A field of a class.
	 *
	 * @author Christophe Herreman
	 */
	public class Field extends AbstractMember {

		/**
		 * Creates a new Field objects.
		 */
		public function Field(name:String, type:String, declaringType:String, isStatic:Boolean, applicationDomain:ApplicationDomain, metaData:HashArray = null) {
			super(name, type, declaringType, isStatic, applicationDomain, metaData);
		}

		/**
		 * Returns the value of the field.
		 */
		public function getValue(target:* = null):* {
			if (!target) {
				target = declaringType.clazz;
			}
			return target[name];
		}

	}
}
