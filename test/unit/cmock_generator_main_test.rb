
$ThisIsOnlyATest = true

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + "/../../lib/cmock_generator"

class MockedPluginHelper
  def initialize return_this
    @return_this = return_this
  end
  
  def include_files
    return @return_this
  end
  
  def instance_structure( name, args, rettype )
    return "  #{@return_this}_#{name}(#{args}, #{rettype})"
  end
  
  def mock_verify( name )
    return "  #{@return_this}_#{name}"
  end
  
  def mock_destroy( name, args, rettype )
    return "  #{@return_this}_#{name}(#{args}, #{rettype})"
  end
  
  def mock_implementation_prefix(name, rettype)
    return "  Pre#{name}#{@return_this}.#{rettype}"
  end
  
  def mock_implementation(name, args)
    return "  Mock#{name}#{@return_this}(#{args.join(", ")})"
  end
end

class CMockGeneratorTest < Test::Unit::TestCase
  def setup
    create_mocks :config, :file_writer, :utils, :plugins
    @module_name = "PoutPoutFish"
    
    @config.expect.tab.returns("  ")
    @config.expect.mock_prefix.returns("Mock")
    @cmock_generator = CMockGenerator.new(@config, @module_name, @file_writer, @utils, @plugins)
  end

  def teardown
  end
  
  should "have set up internal accessors correctly on init" do
    assert_equal(@config,       @cmock_generator.config)
    assert_equal(@module_name,  @cmock_generator.module_name)
    assert_equal(@file_writer,  @cmock_generator.file_writer)
    assert_equal(@utils,        @cmock_generator.utils)
    assert_equal(@plugins,      @cmock_generator.plugins)
    assert_equal("Mock#{@module_name}", @cmock_generator.mock_name)
    assert_equal("  ",          @cmock_generator.tab)
  end
  
  should "create the top of a header file" do
    @config.expect.mock_prefix.returns("Mock")
    @config.expect.includes.returns("included.h")
    orig_filename = "PoutPoutFish.h"
    define_name = "MOCKPOUTPOUTFISH_H"
    mock_name = "MockPoutPoutFish"
    output = []
    expected = [ "/* AUTOGENERATED FILE. DO NOT EDIT. */\n",
                 "#ifndef _#{define_name}\n",
                 "#define _#{define_name}\n\n",
                 "#include \"included.h\"\n",
                 "#include \"#{orig_filename}\"\n\n",
                 "void #{mock_name}_Init(void);\n",
                 "void #{mock_name}_Destroy(void);\n",
                 "void #{mock_name}_Verify(void);\n\n"
               ]
    
    @cmock_generator.create_mock_header_header(output, "MockPoutPoutFish.h")
    
    assert_equal(expected, output)
  end
  
  should "append the proper footer to the header file" do 
    output = []
    expected = ["\n#endif\n"]
    
    @cmock_generator.create_mock_header_footer(output)
    
    assert_equal(expected, output)
  end
  
  should "create a proper heading for a source file" do
    output = []
    expected = [ "/* AUTOGENERATED FILE. DO NOT EDIT. */\n",
                 "#include <string.h>\n",
                 "#include <stdlib.h>\n",
                 "#include <setjmp.h>\n",
                 "#include \"unity.h\"\n",
                 "#include \"PluginRequiredHeader.h\"\n",
                 "#include \"MockPoutPoutFish.h\"\n\n"
               ]
    @plugins.expect.run(:include_files).returns("#include \"PluginRequiredHeader.h\"\n")
  
    @cmock_generator.create_source_header_section(output, "MockPoutPoutFish.c")
    
    assert_equal(expected, output)
  end
  
  should "create the instance structure where it is needed when no functions" do 
    output = []
    functions = []
    expected = [ "static struct MockPoutPoutFishInstance\n",
                 "{\n",
                 "  unsigned char placeHolder;\n",
                 "  unsigned char allocFailure;\n",
                 "} Mock;\n\n"
               ]
    
    @cmock_generator.create_instance_structure(output, functions)
    
    assert_equal(expected, output.flatten)
  end
  
  should "create the instance structure where it is needed when functions required" do 
    output = []
    functions = [ { :name => "First", :args => "int Candy", :rettype => "int" }, 
                  { :name => "Second", :args => "bool Smarty", :rettype => "char" }
                ]
    expected = [ "static struct MockPoutPoutFishInstance\n",
                 "{\n",
                 "  unsigned char allocFailure;\n",
                 "  Uno_First(int Candy, int)",
                 "  Dos_First(int Candy, int)",
                 "  Uno_Second(bool Smarty, char)",
                 "  Dos_Second(bool Smarty, char)",
                 "} Mock;\n\n"
               ]
    @plugins.expect.run(:instance_structure, functions[0]).returns(["  Uno_First(int Candy, int)","  Dos_First(int Candy, int)"])
    @plugins.expect.run(:instance_structure, functions[1]).returns(["  Uno_Second(bool Smarty, char)","  Dos_Second(bool Smarty, char)"])
    
    @cmock_generator.create_instance_structure(output, functions)
    
    assert_equal(expected, output.flatten)
  end
  
  should "create extern declarations for source file" do
    output = []
    expected = [ "extern jmp_buf AbortFrame;\n",
                 "extern int GlobalExpectOrder;\n",
                 "extern int GlobalVerifyOrder;\n",
                 "\n" ]
    
    @cmock_generator.create_extern_declarations(output)
    
    assert_equal(expected, output.flatten)
  end
  
  should "create mock verify functions in source file when no functions specified" do
    functions = []
    output = []
    expected = [ "void MockPoutPoutFish_Verify(void)\n{\n",
                 "  TEST_ASSERT_EQUAL(0, Mock.allocFailure);\n",
                 "}\n\n"
               ]
    
    @cmock_generator.create_mock_verify_function(output, functions)
    
    assert_equal(expected, output.flatten)
  end
  
  should "create mock verify functions in source file when extra functions specified" do
    functions = [ { :name => "First", :args => "int Candy", :rettype => "int" }, 
                  { :name => "Second", :args => "bool Smarty", :rettype => "char" } 
                ]
    output = []
    expected = [ "void MockPoutPoutFish_Verify(void)\n{\n",
                 "  TEST_ASSERT_EQUAL(0, Mock.allocFailure);\n",
                 "  Uno_First",
                 "  Dos_First",
                 "  Uno_Second",
                 "  Dos_Second",
                 "}\n\n"
               ]
    @plugins.expect.run(:mock_verify, functions[0]).returns(["  Uno_First","  Dos_First"])
    @plugins.expect.run(:mock_verify, functions[1]).returns(["  Uno_Second","  Dos_Second"])
    
    @cmock_generator.create_mock_verify_function(output, functions)
    
    assert_equal(expected, output.flatten)
  end
  
  should "create mock init functions in source file" do
    output = []
    expected = [ "void MockPoutPoutFish_Init(void)\n{\n",
                 "  MockPoutPoutFish_Destroy();\n",
                 "}\n\n"
               ]
    
    @cmock_generator.create_mock_init_function(output)
    
    assert_equal(expected, output)
  end
  
  should "create mock destroy functions in source file when no functions specified" do
    functions = []
    output = []
    expected = [ "void MockPoutPoutFish_Destroy(void)\n{\n",
                 "  memset(&Mock, 0, sizeof(Mock));\n",
                 "}\n\n"
               ]
    
    @cmock_generator.create_mock_destroy_function(output, functions)
    
    assert_equal(expected, output.flatten)
  end
  
  should "create mock destroy functions in source file when extra functions specified" do
    functions = [ { :name => "First", :args => "int Candy", :rettype => "int" }, 
                  { :name => "Second", :args => "bool Smarty", :rettype => "char" } 
                ]
    output = []
    expected = [ "void MockPoutPoutFish_Destroy(void)\n{\n",
                 "  Uno_First(int Candy, int)",
                 "  Dos_First(int Candy, int)",
                 "  Uno_Second(bool Smarty, char)",
                 "  Dos_Second(bool Smarty, char)",
                 "  memset(&Mock, 0, sizeof(Mock));\n",
                 "}\n\n"
               ]
    @plugins.expect.run(:mock_destroy, functions[0]).returns(["  Uno_First(int Candy, int)","  Dos_First(int Candy, int)"])
    @plugins.expect.run(:mock_destroy, functions[1]).returns(["  Uno_Second(bool Smarty, char)","  Dos_Second(bool Smarty, char)"])
    
    @cmock_generator.create_mock_destroy_function(output, functions)
    
    assert_equal(expected, output.flatten)
  end
  
  should "create mock implementation functions in source file" do
    function = { :modifier => "static", 
                 :rettype => "bool", 
                 :args_string => "uint32 sandwiches, const char* named", 
                 :args => ["uint32 sandwiches", "const char* named"],
                 :var_arg => nil,
                 :name => "SupaFunction",
                 :attributes => "__inline"
               }
    output = []
    expected = [ "__inline ",
                 "static bool SupaFunction(uint32 sandwiches, const char* named)\n",
                 "{\n",
                 "  PreSupaFunctionUno.bool",
                 "  PreSupaFunctionDos.bool",
                 "  MockSupaFunctionUno(uint32 sandwiches, const char* named)",
                 "  MockSupaFunctionDos(uint32 sandwiches, const char* named)",
                 "  UtilsSupaFunction.bool",
                 "}\n\n"
               ]
    @plugins.expect.run(:mock_implementation_prefix, function).returns(["  PreSupaFunctionUno.bool","  PreSupaFunctionDos.bool"])
    @plugins.expect.run(:mock_implementation, function).returns(["  MockSupaFunctionUno(uint32 sandwiches, const char* named)","  MockSupaFunctionDos(uint32 sandwiches, const char* named)"])
    @utils.expect.code_handle_return_value(function,"  ").returns("  UtilsSupaFunction.bool")
    
    @cmock_generator.create_mock_implementation(output, function)
    
    assert_equal(expected, output.flatten)
  end
  
  should "create mock implementation functions in source file with different options" do
    function = { :modifier => "", 
                 :rettype => "int", 
                 :args_string => "uint32 sandwiches", 
                 :args => ["uint32 sandwiches"],
                 :var_arg => "corn ...",
                 :name => "SupaFunction",
                 :attributes => nil
               }
    output = []
    expected = [ "int SupaFunction(uint32 sandwiches, corn ...)\n",
                 "{\n",
                 "  PreSupaFunctionUno.int",
                 "  PreSupaFunctionDos.int",
                 "  MockSupaFunctionUno(uint32 sandwiches)",
                 "  MockSupaFunctionDos(uint32 sandwiches)",
                 "  UtilsSupaFunction.int",
                 "}\n\n"
               ]
    @plugins.expect.run(:mock_implementation_prefix, function).returns(["  PreSupaFunctionUno.int","  PreSupaFunctionDos.int"])
    @plugins.expect.run(:mock_implementation, function).returns(["  MockSupaFunctionUno(uint32 sandwiches)","  MockSupaFunctionDos(uint32 sandwiches)"])
    @utils.expect.code_handle_return_value(function,"  ").returns("  UtilsSupaFunction.int")
    
    @cmock_generator.create_mock_implementation(output, function)
    
    assert_equal(expected, output.flatten)
  end
end
