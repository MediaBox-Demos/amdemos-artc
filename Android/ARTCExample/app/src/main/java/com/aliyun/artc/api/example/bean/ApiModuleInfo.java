package com.aliyun.artc.api.example.bean;

public class ApiModuleInfo {
    private String module;
    private String titleName;

    public String getTitleName() {
        return titleName;
    }

    public String getModule() {
        return module;
    }

    public ApiModuleInfo moduleName(String module) {
        this.module = module;
        return this;
    }


    public ApiModuleInfo titleName(String titleName) {
        this.titleName = titleName;
        return this;
    }

}
