using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

static class App {
    static string Script() {
        using(var stream=Assembly.GetExecutingAssembly().GetManifestResourceStream("Fix.ps1"))
        using(var reader=new StreamReader(stream,Encoding.UTF8)) return reader.ReadToEnd();
    }
    static string PowerShell { get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe"); } }
    static ProcessStartInfo Command(string action, string output) {
        string command="& {\n"+Script()+"\n} -Action "+action;
        if(output!=null) command+=" -OutputFile '"+output.Replace("'","''")+"'";
        return new ProcessStartInfo(PowerShell,"-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand "+Convert.ToBase64String(Encoding.Unicode.GetBytes(command)));
    }
    public static string Run(string action, bool elevate) {
        string folder=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Ultimate2CFix");
        Directory.CreateDirectory(folder);
        string output=Path.Combine(folder,DateTime.Now.ToString("yyyyMMdd-HHmmss-fff")+"-"+Guid.NewGuid().ToString("N")+".txt");
        var start=Command(action,output);
        start.UseShellExecute=elevate;
        start.WindowStyle=ProcessWindowStyle.Hidden;
        if(elevate) start.Verb="runas";
        else { start.CreateNoWindow=true; start.RedirectStandardError=true; }
        using(var p=Process.Start(start)) {
            string errors=elevate?"":p.StandardError.ReadToEnd();
            p.WaitForExit();
            string result=File.Exists(output)?File.ReadAllText(output,Encoding.UTF8):"No report was received. "+errors;
            if(p.ExitCode!=0) result="The operation did not complete.\r\n"+result;
            return result+"\r\n\r\nReport: "+output;
        }
    }
    [STAThread] static int Main(string[] args) {
        if(args.Length>0) {
            if(args[0]=="--scan-to" && args.Length==2) {
                try { File.WriteAllText(args[1],Run("Scan",false),Encoding.UTF8); return 0; }
                catch(Exception e) { File.WriteAllText(args[1],e.ToString()); return 1; }
            }
            return 2;
        }
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new FixWindow());
        return 0;
    }
}

sealed class FixWindow : Form {
    readonly TextBox report=new TextBox();
    readonly Button scan=new Button(), repair=new Button(), restore=new Button();
    public FixWindow() {
        Text="Ultimate 2C - Fix Duplicates v0.1";
        ClientSize=new Size(780,540); MinimumSize=new Size(650,490);
        StartPosition=FormStartPosition.CenterScreen;
        Font=new Font("Segoe UI",10);
        var layout=new TableLayoutPanel { Dock=DockStyle.Fill,Padding=new Padding(18),ColumnCount=1,RowCount=4 };
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute,76));
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute,48));
        layout.RowStyles.Add(new RowStyle(SizeType.Percent,100));
        layout.RowStyles.Add(new RowStyle(SizeType.Absolute,78));
        var intro=new Label { Dock=DockStyle.Fill,Text="8BitDo Ultimate 2C Wireless\r\nConnect the controller by USB cable or connect its 2.4G receiver.\r\nRepair disables the two auxiliary interfaces listed as extra controllers." };
        var buttons=new FlowLayoutPanel { Dock=DockStyle.Fill };
        scan.Text="Check"; repair.Text="Repair"; restore.Text="Restore";
        foreach(var b in new[]{scan,repair,restore}) { b.Width=145; b.Height=34; buttons.Controls.Add(b); }
        report.Multiline=true; report.ReadOnly=true; report.ScrollBars=ScrollBars.Both;
        report.WordWrap=false; report.Dock=DockStyle.Fill; report.Font=new Font("Consolas",9);
        var note=new Label { Dock=DockStyle.Fill,Padding=new Padding(0,10,0,0),Text="Run Repair once over USB and once with the receiver. If duplicates return after changing ports, run Repair again.\r\nRestore enables the connected auxiliary interfaces. You may need it before configuration or firmware updates. No installation required." };
        layout.Controls.Add(intro,0,0); layout.Controls.Add(buttons,0,1); layout.Controls.Add(report,0,2); layout.Controls.Add(note,0,3);
        Controls.Add(layout);
        scan.Click+=async delegate { await Execute("Scan"); };
        repair.Click+=async delegate { await Execute("Repair"); };
        restore.Click+=async delegate { await Execute("Restore"); };
        Shown+=async delegate { await Execute("Scan"); };
    }
    async Task Execute(string action) {
        scan.Enabled=repair.Enabled=restore.Enabled=false;
        report.Text="Checking Ultimate 2C interfaces...";
        try { report.Text=await Task.Run(()=>App.Run(action,action!="Scan")); }
        catch(System.ComponentModel.Win32Exception e) { report.Text=e.NativeErrorCode==1223?"Administrator permission was canceled. No changes were applied.":e.Message; }
        catch(Exception e) { report.Text="Could not complete the operation: "+e.Message; }
        finally { scan.Enabled=repair.Enabled=restore.Enabled=true; }
    }
}
