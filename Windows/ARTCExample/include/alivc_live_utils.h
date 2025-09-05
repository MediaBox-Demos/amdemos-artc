#ifndef alivc_live_utils_h
#define alivc_live_utils_h

#include "alivc_live_define.h"

/**
 * @brief AliRTCSdk namespace
 */
namespace AliVCSDK_ARTC
{

  /**
    * @brief sdk封装string，便于平台兼容
    */
  class ALIVC_LIVE_API String
  {
  public:
    String(const char* str = 0);
    String(const String &other);
    String & operator=(const String& other);
    String & operator=(const char *str);
    String operator+(const String &other) const;
    String & operator+=(const String& other);
    virtual ~String(void);
    bool operator==(const String&) const;
    char& operator[](unsigned int);

    const char *c_str() const;
    bool isEmpty() const;
    int size() const;

  private:
    char *data{ nullptr };
    int dataLen{ 0 };
  };

  /**
    * @brief sdk封装数组，便于平台兼容
    */
  class ALIVC_LIVE_API StringArray
  {
  public:
    StringArray();
    virtual ~StringArray();
    StringArray(const StringArray &other);
    StringArray & operator=(const StringArray& other);

    void addString(const String &s);
    void clear();
    int size() const;
    String at(int index) const;

  private:
    void *data{ nullptr };
  };

  /**
    * @brief sdk封装字典hash表，便于平台兼容
    */
  class ALIVC_LIVE_API Dictionary
  {
  public:
    Dictionary();
    virtual ~Dictionary();
    Dictionary(const Dictionary &other);
    Dictionary & operator=(const Dictionary& other);

    void setValue(const char *key, const char  *val);
    void setValue(const char *key, bool val);
    String getValue(const char *key);
    bool getBoolValue(const char *key, bool defVal);
    StringArray keys() const;

  private:
    void *data{ nullptr };
  };
}

#endif /*alivc_live_utils_h*/
