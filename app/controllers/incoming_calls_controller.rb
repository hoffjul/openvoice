class IncomingCallsController < ApplicationController

  before_filter :require_user, :only => [:index, :show, :new, :destroy]

  def index
    @user = current_user
    @incoming_calls = @user.incoming_calls.reverse
    @incoming_calls = @incoming_calls.paginate(:page => params[:page],:per_page => 15)
    respond_to do |format|
      format.html
      format.xml { render :xml => @incoming_calls }
      format.json { render :json => @incoming_calls }
    end
  end

  def show
    @incoming_call = IncomingCall.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml => @incoming_call }
    end
  end

  def new
    @incoming_call = IncomingCall.new

    respond_to do |format|
      format.html
      format.xml { render :xml => @incoming_call }
    end
  end

  def create
    @incoming_call = IncomingCall.new(params[:incoming_call])

    respond_to do |format|
      if @incoming_call.save
        flash[:notice] = 'CallLog was successfully created.'
        format.html { redirect_to(@incoming_call) }
        format.xml  { render :xml => @incoming_call, :status => :created, :location => @incoming_call }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @incoming_call.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @incoming_call = IncomingCall.find(params[:id])
    @incoming_call.destroy

    respond_to do |format|
      format.html { redirect_to(user_incoming_calls_path) }
      format.xml  { head :ok }
    end
  end

  def user_menu
    value = params[:result][:actions][:value]
    conf_id = params[:conf_id]
    case value
      when "connect"
        tropo = Tropo::Generator.new do
          conference(:name => "conference",
                     :id => conf_id,
                     :terminator => "ring(*)")
        end
        render :json => tropo.response
      when "voicemail"
        session_id = params[:session_id]
        call_id = params[:call_id]
        voicemail_url = "http://api.tropo.com/1.0/sessions/#{session_id}/calls/#{call_id}/events?action=create&name=voicemail"
        open(voicemail_url)
        tropo = Tropo::Generator.new do
          say 'sending caller to voicemail, goodbye'
          hangup
        end
        render :json => tropo.response
      when "listenin"
        caller_id = CGI::escape(params[:caller_id])
        user_id = params[:user_id]
        user_name = User.find(user_id).name
        transcription_id = user_id + "_" + Time.now.to_i.to_s
        tropo = Tropo::Generator.new do
          say ("you have reached #{user_name}\'s voicemail.  Please speak after the beep.")
          start_recording(:name => "recording",
            :format => "audio/wav",
            :url => "#{SERVER_URL}/voicemails/create?caller_id=#{caller_id}&transcription_id=" + transcription_id + "&user_id=" + user_id
          )
          conference(:name => "conference",
                     :id => conf_id,
                     :mute => true,
                     :terminator => "*")
        end
        render :json => tropo.response
    end
  end
end
