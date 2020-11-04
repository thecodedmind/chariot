class String
  def stripf; m = self.dup; while m.include? "  "; m.gsub! "  ", " "; end; m.strip; end;
  def stripchars; m = self.dup; m.sub! "+", ""; m.sub! "*", ""; m.sub! "^", ""; m.sub! "-", ""; m.strip; end;
  def plaintext; m = self.dup; m.gsub!(/([^A-Za-z\d\s])*/, ''); m.stripf.downcase;end
end

class Session
  def initialize; @users = {};end;
  def user(name); if @users.key? name; return @users[name]; else; return {"topic" => "standard", "vars" => {}}; end; end;
  def setv(name, key, var); u = self.user(name); u[key] = var; @users[name] = u; end;
  def getv(name, key); u = self.user(name); u[key]; end;
end

class CodedMind
  def initialize
    @data = { "topics" => {}, "subs" => {}, "vars" => {}, "globals" => {}, "arrays" => {}, "inverts" => {} }
    @commands = {}
    @session = Session.new
    self.addCommand("set") { |s, args| s.setv args[0], args[1]; ""; }
    self.addCommand("get") { |s, args| s.getv args[0]; }
    self.addCommand("invert") { |s, args|
      s.data["inverts"].each do |k, v|
        f = args.join(" ")
        re = /(\A|\s)\Q#{k}\E(\s|\Z)/
        if f =~ re
          f.gsub! re, v
        end
        
      end
      f
    }
  end
  
  attr_reader :session
  attr_reader :data

  def setv(key, var);@data["vars"][key] = var;end;
  def getv(key, d = "none"); if @data["vars"].key? key; return @data["vars"][key]; else; return d; end; end;
  def callCommand(trigger, args); if @data["globals"].key? trigger; return @data["globals"][trigger].call(self, args); end; end;
  def addCommand(trigger, &fn); @data["globals"][trigger] = fn; end;
  def topic(name); if @data["topics"].key? name; return @data["topics"][name]; else; return nil; end; end;

  def checkif(ch)
    k = ch.split(" ")[0]; op = ch.split(" ")[1]; v = ch.split(" ")[2]
    op == "==" if op == "is"
    op == "==" if op == "eq"
    if k.start_with? "$"; k = handleVars k; end; if v.start_with? "$"; v = handleVars v; end;
    if v.is_i?; v = v.to_i; else; v = '"'+v+'"'; end; if k.is_i?; k = k.to_i; else; k = '"'+k+'"'; end;
    return eval("#{k} #{op} #{v}")
  end

  def handleVars(s)
    @data["vars"].each { |k, v|
      if s.include? "$#{k}";
        s = s.sub("$#{k}", v);
      end
    }
    s
  end

  def handleTrigger(t)
    r = t["replies"]
    valids = []
    conds = []
    for reply in r
      if reply["condition"] != nil
        conds.append(reply) if self.checkif(reply["condition"]) == true
      else
        valids.append reply
      end
    end
    
    if conds.length > 0; t = conds[0]["text"]; return t;
    elsif valids.length > 0; return valids.sample["text"];
    else; return nil;
    end
  end
  
  def handleSubs(s)
    f = s.dup
    @data["subs"].each { |k, v|
      re = /(\A|\s)\Q#{Regexp.quote(k)}\E(\s|\Z)/
      if f =~ re
        f.gsub! re, v
      end
    }
    f
  end
  
  def handleInternals(s)
    # define generics
    optionals_in = "(\\s?)(.*?)(\\s?)"; arrays_out = /\(\@\w*\)/; optional_out = /\[\w*\]/
    ar = s.scan(arrays_out); op = s.scan(optional_out)

    #optionals
    if op.length > 0; for o in op; o.sub!("[", "").sub!("]", ""); s.sub!(" ["+o+"] ", optionals_in); end; end
    
    #arrays
    if ar.length > 0; for a in ar; a.sub!("(@", "").sub!(")", "");s.sub!("(@"+a+")", "("+@data["arrays"][a].join("|")+")");end;end
    
    s
  end

  def isLastMsg(user, reply); return user["previous"].downcase =~ /\A#{reply["previous"].downcase}\Z/; end
  
  def reply(user, txt)
    # define internal variables and filter input
    txt = self.handleSubs txt; txt = txt.dup.plaintext
    setv("last_user", user); setv("last_input", txt)
    
    # get BEGIN and FALLBACK
    b = @data["begin"]; u = @session.user user; t = self.topic(u["topic"]); fallback = nil; fnd = []; prevs = []

    # filtering
    for o in t
      if o["trigger"] == "FALLBACK" or o["trigger"] == "*"; fallback = o
      else
        r = Regexp.new o["trigger"]
        if txt =~ /\A#{r}\Z/; if o["previous"] != nil; if u["previous"] != nil and self.isLastMsg(u, o); prevs.append o; end;
          else;fnd.append o; end;end       
      end
    end

    #define output container
    opts = []; if prevs.length > 0; opts = prevs; else; opts = fnd; end

    # deciding which container to hand to opts for output, if we should use fallbacks
    if opts.length == 0; if fallback != nil; opts.append fallback
      elsif @data["fallback"] != nil; opts.append @data["fallback"]
      else; return self.getv("no_reply_txt")
      end
    end

    ok = self.handleTrigger(b)
    if ok == "{ok}"
      # TODO expand to pick which one to use dynamically, take weighting in to account
      # TODO iterate, find one with heighest weight
      # TODO if highest weight is still 1, send random, else send highest
      reply = opts[0].dup
      sendReply(user, txt, reply)
    else
      rep = handleVars(ok.dup)
      rep = handleCmd(rep)
      rep.dup
    end
    
  end

  def sendReply(user, txt, repl)
    rep = handleTrigger(repl.dup)
    @session.setv user, "previous", rep
    rep = handleVars(rep.dup)
    r = Regexp.new repl["trigger"]
    scans = txt.scan(r)[0]

    if scans.class != String and scans != nil
      scans.map!(&:strip)
      scans = scans - [""]
      scans = scans.reject { |k| k == "" }
      if scans.length > 0
        i = 0
        for v in scans
          rep.gsub! "<#{i}>", v
          i += 1
        end        
      end        
    end

    rep = handleCmd(rep)
    rep.dup
  end
  
  def handleCmd(ln)
    r = /{(.*?)}/
    scans = ln.scan(r)
    if scans.length > 0
      for en in scans
        en = en[0]
        cmdl = en.gsub("{", "").gsub("}", "")
        command = cmdl.split(" ")[0]
        params = cmdl.split(" ")[1..-1].join(" ").split(";")
        params.map!(&:strip)
        
        res = callCommand(command, params)
        ln.sub!("{"+cmdl+"}", res)
      end
    end
    return ln
  end
  
  def load(file);self.parseLines(IO.readlines(file));end
  def parseText(txt);self.parseLines txt.split("\n");end
  
  def parseLines(lines)
    @topic = "standard"
    @block = nil
    def push;
      if @block != nil;
        if @block["trigger"] == "BEGIN";      @data["begin"] = @block.dup;
        elsif @block["trigger"] == "FALLBACK!" or @block["trigger"] == "*!";  @data["fallback"] = @block.dup;
        else; @data["topics"][@topic] = [] if @data["topics"][@topic] == nil;
          @data["topics"][@topic].append @block.dup;end; @block = nil;end; end

    
    for ln in lines
      weight = 1
      if ln =~ /\{weight=\d\}/;m = ln.scan(/\{weight=\d\}/)[0];weight = m.sub!("{weight=", "").sub!("}", "").to_i;ln.sub! "{weight="+m+"}", "";end
      if ln.start_with? "<<"
        push
        @topic = ln.split(" ")[1..-1].join(" ")
      elsif ln.start_with? "!" # define variable
        t = ln.split(" ")[1];       l = ln.split(" ")[2..-1].join(" ");     k = l.split("=")[0].strip;    v = l.split("=")[1].strip
        case t
        when "var"
          @data['vars'][k] = v
        when "array"
          arr = []
          if v.include? ","; arr = v.split(",")
          elsif v.include? "|"; arr = v.split("|")
          elsif v.include? ";"; arr = v.split("|")
          elsif v.include? ":"; arr = v.split("|")
          else; arr = v.split(" "); end
          arr.map!(&:strip); @data['arrays'][k] = arr
          
        when "sub"
          @data['subs'][k] = v
        when "invert"
          @data['inverts'][k] = v
        end
        
        
      elsif ln.start_with? "+" or ln.start_with? "trigger" 
        push; ln = self.handleInternals(ln); line = ln.split(" ")[1..-1].join(" ").stripf; r = line.scan(/{topic=(.*)}/)
        if r.length > 0;  @topic = r[0][0]; line = line.sub("{topic=#{@topic}}", ""); end
        @block = {"trigger" => line.stripf, "replies" => [], "weight" => weight, "previous" => nil}

        
      elsif ln.start_with? "-"  or ln.start_with? "reply"
        if @block != nil
          @block["replies"].append({"text" => ln.split(" ")[1..-1].join(" ").stripf, "condition" => nil, "weight" => weight})
        end
        
      elsif ln.start_with? "%"  or ln.start_with? "previous"
        if @block != nil;@block["previous"] = ln.split(" ")[1..-1].join(" ").stripf;end
        
      elsif ln.start_with? "*" or ln.start_with? "if"
        if @block != nil
          @block["replies"].append({"text" => ln.split("=>")[1].stripf,
                                    "condition" =>  ln.split("=>")[0].split(" ")[1..-1].join(" ").stripf, "weight" => weight})
        end
        
      elsif ln.start_with? "^" or ln.start_with? "append"# append to previous line
        if @block != nil;  @block["replies"][-1]["text"] += ln.split(" ")[1..-1].join(" ").stripf; end
      end
    end
    push
  end

  def load_directory(dir, ext = [".rs", ".ai", ".brain"])
    Dir.foreach(dir) do |entry| for e in ext; if entry.end_with? e; self.load(dir+entry); end; end; end;
  end
end
