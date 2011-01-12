/*
* Copyright 2007-2011 the original author or authors.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
package org.as3commons.bytecode.proxy.impl {
	import flash.utils.ByteArray;
	
	import org.as3commons.bytecode.abc.ExceptionInfo;
	import org.as3commons.bytecode.abc.MethodBody;
	import org.as3commons.bytecode.abc.enum.Opcode;
	import org.as3commons.bytecode.as3commons_bytecode;
	import org.as3commons.bytecode.emit.IClassBuilder;
	import org.as3commons.bytecode.emit.IMethodBuilder;
	import org.as3commons.bytecode.emit.IPropertyBuilder;
	import org.as3commons.bytecode.proxy.IClassIntroducer;
	import org.as3commons.bytecode.proxy.IProxyFactory;
	import org.as3commons.bytecode.proxy.error.ProxyBuildError;
	import org.as3commons.bytecode.reflect.ByteCodeAccessor;
	import org.as3commons.bytecode.reflect.ByteCodeMethod;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.bytecode.reflect.ByteCodeVariable;
	import org.as3commons.bytecode.util.AbcSpec;
	import org.as3commons.lang.Assert;
	import org.as3commons.reflect.Field;
	import org.as3commons.reflect.Method;

	public class ClassIntroducer implements IClassIntroducer {

		private var _methodProxyFactory:MethodProxyFactory;

		public function ClassIntroducer(methodProxyFactory:MethodProxyFactory) {
			super();
			initClassIntroducer(methodProxyFactory);
		}

		protected function initClassIntroducer(methodProxyFactory:MethodProxyFactory):void {
			Assert.notNull(methodProxyFactory, "methodProxyFactory argument must not be null");
			_methodProxyFactory = methodProxyFactory;
		}

		public function introduce(className:String, classBuilder:IClassBuilder):void {
			var type:ByteCodeType = ByteCodeType.forName(className);
			if (type != null) {
				internalIntroduce(type, classBuilder);
			} else {
				throw new ProxyBuildError(ProxyBuildError.INTRODUCED_CLASS_NOT_FOUND, className);
			}
		}

		protected function internalIntroduce(type:ByteCodeType, classBuilder:IClassBuilder):void {
			classBuilder.implementInterfaces(type.interfaces);
			for each (var field:Field in type.fields) {
				introduceField(field, classBuilder);
			}
			for each (var method:Method in type.methods) {
				if (method is ByteCodeMethod) {
					introduceMethod(ByteCodeMethod(method), classBuilder, type);
				}
			}
		}

		protected function introduceMethod(method:ByteCodeMethod, classBuilder:IClassBuilder, type:ByteCodeType):void {
			var memberInfo:MemberInfo = new MemberInfo(method.name, method.namespaceURI);
			var methodBuilder:IMethodBuilder = _methodProxyFactory.proxyMethod(classBuilder, type, memberInfo, false);
			methodBuilder.isOverride = false;
			var methodBody:MethodBody = new MethodBody();
			methodBody.initScopeDepth = method.initScopeDepth;
			methodBody.maxStack = method.maxStack;
			methodBody.localCount = method.localCount;
			methodBody.maxScopeDepth = method.maxScopeDepth;
			var originalPosition:int = type.byteArray.position;
			try {
				type.byteArray.position = method.bodyStartPosition;
				methodBody.opcodes = Opcode.parse(type.byteArray, method.bodyLength, methodBody, type.constantPool);
				methodBody.exceptionInfos = extractExceptionInfos(type.byteArray, type);
			} finally {
				type.byteArray.position = originalPosition;
			}
			methodBuilder.as3commons_bytecode::setMethodBody(methodBody);
		}

		protected function extractExceptionInfos(input:ByteArray, type:ByteCodeType):Array {
			var exceptionInfos:Array = [];
			var exceptionCount:int = AbcSpec.readU30(input);
			for (var exceptionIndex:int = 0; exceptionIndex < exceptionCount; ++exceptionIndex) {
				var exceptionInfo:ExceptionInfo = new ExceptionInfo();
				exceptionInfo.exceptionEnabledFromCodePosition = AbcSpec.readU30(input);
				exceptionInfo.exceptionEnabledToCodePosition = AbcSpec.readU30(input);
				exceptionInfo.codePositionToJumpToOnException = AbcSpec.readU30(input);
				exceptionInfo.exceptionTypeName = type.constantPool.stringPool[AbcSpec.readU30(input)];
				exceptionInfo.nameOfVariableReceivingException = type.constantPool.stringPool[AbcSpec.readU30(input)];
				exceptionInfos[exceptionInfos.length] = exceptionInfo;
			}
			return exceptionInfos;
		}

		protected function introduceField(field:Field, classBuilder:IClassBuilder):void {
			if (field is ByteCodeAccessor) {
				introduceAccessor(ByteCodeAccessor(field), classBuilder);
			} else if (field is ByteCodeVariable) {
				introduceVariable(ByteCodeVariable(field), classBuilder);
			}
		}

		protected function introduceVariable(byteCodeVariable:ByteCodeVariable, classBuilder:IClassBuilder):void {
			var propertyBuilder:IPropertyBuilder = classBuilder.defineProperty(byteCodeVariable.name, byteCodeVariable.type.fullName, byteCodeVariable.initializedValue);
			propertyBuilder.namespaceURI = byteCodeVariable.namespaceURI;
			propertyBuilder.scopeName = byteCodeVariable.scopeName;
			propertyBuilder.visibility = ProxyFactory.getMemberVisibility(byteCodeVariable);
		}

		protected function introduceAccessor(byteCodeAccessor:ByteCodeAccessor, classBuilder:IClassBuilder):void {
		}
	}
}