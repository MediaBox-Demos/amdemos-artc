package com.aliyun.artc.api.example;

import static com.aliyun.aio.aio_env.AlivcEnv.GlobalEnv.ENV_DEFAULT;
import static com.aliyun.aio.aio_env.AlivcEnv.GlobalEnv.ENV_SEA;

import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.DefaultItemAnimator;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.alivc.rtc.AliRtcEngine;
import com.aliyun.aio.aio_env.AlivcEnv;
import com.aliyun.artc.api.basicusage.CameraCommonControl.CameraActivity;
import com.aliyun.artc.api.basicusage.VideoBasicUsage.VideoBasicUsageActivity;
import com.aliyun.artc.api.example.adapter.APIExampleListAdapter;
import com.aliyun.artc.api.example.bean.ApiModuleInfo;
import com.aliyun.artc.api.keycenter.ARTCTokenHelper;
import com.aliyun.artc.api.keycenter.GlobalConfig;
import com.aliyun.artc.api.keycenter.utils.SettingStorage;
import com.aliyun.artc.api.example.utils.PermissionUtils;

import com.aliyun.artc.api.quickstart.TokenGenerate.TokenGenerateActivity;
import com.aliyun.artc.api.quickstart.VideoCall.VideoCallActivity;
import com.aliyun.artc.api.quickstart.VoiceChat.VoiceChatActivity;
import com.aliyun.artc.api.basicusage.AudioBasicUsage.AudioBasicUsageActivity;
import com.aliyun.common.AlivcBase;
import com.orhanobut.dialogplus.DialogPlus;
import com.orhanobut.dialogplus.OnDismissListener;
import com.orhanobut.dialogplus.ViewHolder;
import com.aliyun.artc.api.seiusage.SEIActivity;


public class MainActivity extends AppCompatActivity {

    private RecyclerView mApiExampleList;
    private APIExampleListAdapter mApiExampleListAdapter = new APIExampleListAdapter();
    private static final int REQUEST_PERMISSION_CODE = 101;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);

        SettingStorage.getInstance().init(this);

        AlivcEnv.GlobalEnv env = ENV_DEFAULT;
        if(!GlobalConfig.getInstance().getSdkRegion().equals("cn")) {
            env = ENV_SEA;
        }
        AlivcBase.getEnvironmentManager().setGlobalEnvironment(env);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        mApiExampleList = findViewById(R.id.api_example_list);
        mApiExampleListAdapter.setOnItemClickListener((view, position) -> {
            if (checkOrRequestPermission(REQUEST_PERMISSION_CODE)) {
                ApiModuleInfo moduleInfo = (ApiModuleInfo) view.getTag();
                if(moduleInfo.getModule().equals(getString(R.string.token_verify))) {
                    TokenGenerateActivity.startActionActivity(MainActivity.this);
                } else if(moduleInfo.getModule().equals(getString(R.string.video_chat))) {
                    VideoCallActivity.startActionActivity(MainActivity.this);
                } else if(moduleInfo.getModule().equals(getString(R.string.voice_chat_room))){
                    VoiceChatActivity.startActionActivity(MainActivity.this);
                } else if(moduleInfo.getModule().equals(getString(R.string.audio_basic_usage))) {
                    AudioBasicUsageActivity.startActionActivity(MainActivity.this);
                } else if(moduleInfo.getModule().equals(getString(R.string.video_basic_usage))) {
                    VideoBasicUsageActivity.startActionActivity(MainActivity.this);

                }else if(moduleInfo.getModule().equals(getString(R.string.send_text))) {
                    SEIActivity.startActionActivity(MainActivity.this);
                } else if(moduleInfo.getModule().equals(getString(R.string.caemra_common_control))) {
                    CameraActivity.startActionActivity(MainActivity.this);
                }

            } else {
                Toast.makeText(this, "请允许相关权限", Toast.LENGTH_SHORT).show();
            }
        });

        mApiExampleList.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.VERTICAL, false));
        mApiExampleList.setAdapter(mApiExampleListAdapter);
        mApiExampleList.setItemAnimator(new DefaultItemAnimator());

        mApiExampleListAdapter.addModuleInfo(new ApiModuleInfo().moduleName(getString(R.string.token_verify)).titleName(getString(R.string.quick_start)));
        mApiExampleListAdapter.addModuleInfo(new ApiModuleInfo().moduleName(getString(R.string.video_chat)));
        mApiExampleListAdapter.addModuleInfo(new ApiModuleInfo().moduleName(getString(R.string.voice_chat_room)));

        mApiExampleListAdapter.addModuleInfo(new ApiModuleInfo().moduleName(getString(R.string.audio_basic_usage)).titleName(getString(R.string.basic_features)));
        mApiExampleListAdapter.addModuleInfo(new ApiModuleInfo().moduleName(getString(R.string.video_basic_usage)));
        mApiExampleListAdapter.addModuleInfo(new ApiModuleInfo().moduleName(getString(R.string.caemra_common_control)));
        mApiExampleListAdapter.addModuleInfo(new ApiModuleInfo().moduleName(getString(R.string.send_text)));


        mApiExampleListAdapter.addModuleInfo(new ApiModuleInfo().moduleName(getString(R.string.custom_audio_capture)).titleName(getString(R.string.advance_features)));
        mApiExampleListAdapter.addModuleInfo(new ApiModuleInfo().moduleName(getString(R.string.custom_video_capture)));



    }

    public boolean checkOrRequestPermission(int code) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, "android.permission.CAMERA") != PackageManager.PERMISSION_GRANTED
                    || ContextCompat.checkSelfPermission(this, "android.permission.RECORD_AUDIO") != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(PermissionUtils.getPermissions(), code);
                return false;
            }
        }
        return true;
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();
        if (id == R.id.action_settings) {
            // 跳转到设置页面或其他逻辑
            showSettingDialog();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void showSettingDialog() {
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_api_example_setting, null, false);
        ViewHolder viewHolder = new ViewHolder(view);

        ((TextView)view.findViewById(R.id.app_id_input)).setText(ARTCTokenHelper.AppId);
        ((TextView)view.findViewById(R.id.app_key_input)).setText(ARTCTokenHelper.AppKey);
        ((EditText)view.findViewById(R.id.user_id_input)).setText(GlobalConfig.getInstance().getUserId());
        ((TextView)view.findViewById(R.id.sdk_version_input)).setText(AliRtcEngine.getSdkVersion());

        TextView cnTextView = view.findViewById(R.id.sdk_region_cn);
        TextView seaTextView = view.findViewById(R.id.sdk_region_sea);

        String sdkRegion =GlobalConfig.getInstance().getSdkRegion();
        if(!TextUtils.isEmpty(sdkRegion) && sdkRegion.equals("cn")) {
            cnTextView.setSelected(true);
            seaTextView.setSelected(false);
        } else {
            cnTextView.setSelected(false);
            seaTextView.setSelected(true);
        }

        DialogPlus dialogPlus = DialogPlus.newDialog(this)
                .setContentHolder(viewHolder)
                .setGravity(Gravity.CENTER)
                .setOverlayBackgroundResource(android.R.color.transparent)
                .setContentBackgroundResource(R.color.layout_base_dialog_background)
                .setOnClickListener((dialog1, v) -> {
                    if(v.getId() == R.id.btn_confirm){
                        String userId = ((EditText)view.findViewById(R.id.user_id_input)).getText().toString();
                        if(!TextUtils.isEmpty(userId)) {
                            GlobalConfig.getInstance().setUserId(userId);
                        }

                        if(cnTextView.isSelected() && !seaTextView.isSelected()) {
                            GlobalConfig.getInstance().setSdkRegion("cn");
                            AlivcBase.getEnvironmentManager().setGlobalEnvironment(ENV_DEFAULT);
                        } else if(!cnTextView.isSelected() && seaTextView.isSelected()) {
                            GlobalConfig.getInstance().setSdkRegion("sea");
                            AlivcBase.getEnvironmentManager().setGlobalEnvironment(ENV_SEA);
                        }
                    }

                    if(v.getId() == R.id.sdk_region_cn) {
                        ((TextView)view.findViewById(R.id.sdk_region_cn)).setSelected(true);
                        ((TextView)view.findViewById(R.id.sdk_region_sea)).setSelected(false);
                    } else if(v.getId() == R.id.sdk_region_sea) {
                        ((TextView)view.findViewById(R.id.sdk_region_cn)).setSelected(false);
                        ((TextView)view.findViewById(R.id.sdk_region_sea)).setSelected(true);
                    }

                    if (v.getId() == R.id.btn_confirm || v.getId() == R.id.btn_cancel) {
                        dialog1.dismiss();
                    }
                })
                .setOnDismissListener(new OnDismissListener() {
                    @Override
                    public void onDismiss(DialogPlus dialog) {

                    }
                })
                .create();
        dialogPlus.show();
    }

}