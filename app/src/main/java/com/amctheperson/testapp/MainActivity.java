package com.amctheperson.testapp;

import android.app.Activity;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatDelegate;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO);
        setContentView(R.layout.activity_main);

        TextView greeting = findViewById(R.id.greeting);
        EditText name_entry = findViewById(R.id.name_entry);
        Button name_entry_button = findViewById(R.id.name_entry_button);
        name_entry_button.setEnabled(false);

        name_entry.addTextChangedListener(new TextWatcher() {
            @Override
            public void afterTextChanged(Editable editable) {

            }

            @Override
            public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

            }

            @Override
            public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                if(name_entry.getText().toString().isEmpty()){
                    name_entry_button.setEnabled(false);
                    return;
                }
                name_entry_button.setEnabled(true);
            }
        });

        name_entry_button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {

                String newName = name_entry.getText().toString();

                greeting.setText("Hello, " + newName + ".");

            }
        });







    }
}