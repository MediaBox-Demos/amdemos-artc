package com.aliyun.artc.api.basicusage.VideoBasicUsage;

import java.util.List;

public class VideoConfigurationItem {
    public static final int TYPE_SWITCH = 0;
    public static final int TYPE_EDIT_TEXT = 1;
    public static final int TYPE_SPINNER = 2;
    public static final int TYPE_HEADER = 3;

    public int type;
    public String title;
    public boolean switchValue;
    public String editTextValue;
    public String spinnerValue;
    public int spinnerIndex;
    public List<String> spinnerOptions;

    public VideoConfigurationItem(int type, String title) {
        this.type = type;
        this.title = title;
    }

    public static VideoConfigurationItem createSwitchItem(String title, boolean value) {
        VideoConfigurationItem item = new VideoConfigurationItem(TYPE_SWITCH, title);
        item.switchValue = value;
        return item;
    }

    public static VideoConfigurationItem createEditTextItem(String title, String value) {
        VideoConfigurationItem item = new VideoConfigurationItem(TYPE_EDIT_TEXT, title);
        item.editTextValue = value;
        return item;
    }

    public static VideoConfigurationItem createSpinnerItem(String title, int index, List<String> options) {
        VideoConfigurationItem item = new VideoConfigurationItem(TYPE_SPINNER, title);
        item.spinnerIndex = index >=0 && index < options.size() ? index : 0;
        item.spinnerValue = options.get(item.spinnerIndex);
        item.spinnerOptions = options;
        return item;
    }

    public static VideoConfigurationItem createHeaderItem(String title) {
        return new VideoConfigurationItem(TYPE_HEADER, title);
    }
}
