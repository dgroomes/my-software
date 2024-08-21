package dgroomes;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.swing.*;
import javax.swing.event.MouseInputAdapter;
import java.awt.event.MouseEvent;

public class MyWindow {

    private static final Logger log = LoggerFactory.getLogger(MyWindow.class);

    private String messageString = "My IntelliJ Plugin!";
    private JLabel messageLabel;
    private JPanel root;

    public MyWindow() {
        root.addMouseListener(new MouseInputAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                log.info("The plugin window was clicked!");
                messageString += "!";
                MyWindow.this.messageLabel.setText(messageString);
                super.mouseClicked(e);
            }
        });
        this.messageLabel.setText(messageString);
    }


    public JPanel getRootElement() {
        return root;
    }
}
