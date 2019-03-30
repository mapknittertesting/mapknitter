class CommentsController < ApplicationController

  def create
    if logged_in?
      puts current_user.id
      @map = Map.find params[:map_id]

      @comment = @map.comments.new(
        :user_id => current_user.id,
        :body => params[:comment][:body]
      )
      if @comment.save!
        users = @map.comments.collect(&:user)
        users += [@map.user] unless @map.user.nil?
        users.uniq.each do |user|
          unless user.id == current_user.id
            CommentMailer.notify(user,@comment).deliver
          end
        end
      end

      respond_to do |format|
        #format.html { redirect_to "/maps/" + params[:map_id] }
        format.html   { render :partial => 'comments/comment', :locals => {:comment => @comment} }
        #format.js   { render :partial => 'comments/comment', :locals => {:comment => @comment} }
        format.json { render json: @comment, status: :created }
      end
     
    else
      # we intercept this message in /app/assets/javascripts/maps.js
      render :text => "Login required."
    end
  end

  def update
    @comment = Comment.find params[:id]

    if logged_in? && current_user.can_edit?(@comment)
      puts("CAN EDIT\n\n")
      Comment.update(@comment.id, :body => params[:comment][:body])
      redirect_to "/maps/" + params[:map_id]
    else
      flash[:error] = "You do not have permissions to update that comment."
      redirect_to "/login"            
    end
  end

  def destroy
    @comment = Comment.find(params[:id])

    if logged_in? && current_user.can_delete?(@comment)
      @comment.delete 
      flash[:notice] = "Comment deleted."
    else
      flash[:error] = "You do not have permission to delete that comment."
    end
    redirect_to "/maps/#{params[:map_id]}"
  end
end
